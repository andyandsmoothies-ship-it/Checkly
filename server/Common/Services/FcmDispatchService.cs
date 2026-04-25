using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Polly;
using Polly.Registry;

namespace Checkly.Api.Common.Services;

public interface IFcmDispatchService
{
    Task DispatchSyncNeededAsync(Guid userId);
}

public class FcmDispatchService : IFcmDispatchService
{
    private readonly AppDbContext _db;
    private readonly ILogger<FcmDispatchService> _logger;
    private readonly ResiliencePipeline _pipeline;

    public FcmDispatchService(
        AppDbContext db,
        ILogger<FcmDispatchService> logger,
        ResiliencePipelineProvider<string> pipelineProvider)
    {
        _db = db;
        _logger = logger;
        _pipeline = pipelineProvider.GetPipeline("fcm");
    }

    public async Task DispatchSyncNeededAsync(Guid userId)
    {
        var ct = CancellationToken.None;
        var tokens = await _db.UserDeviceTokens
            .Where(x => x.UserId == userId)
            .ToListAsync(ct);

        if (!tokens.Any())
        {
            return;
        }

        var fcmTokens = tokens.Select(x => x.FcmToken).ToList();

        var message = new MulticastMessage
        {
            Tokens = fcmTokens,
            Data = new Dictionary<string, string>
            {
                { "event", "sync_needed" }
            }
        };

        try
        {
            var messaging = FirebaseMessaging.DefaultInstance;
            if (messaging == null)
            {
                _logger.LogWarning("FirebaseAdmin is not initialized. Cannot dispatch FCM message.");
                return;
            }

            var response = await _pipeline.ExecuteAsync(
                async token => await messaging.SendEachForMulticastAsync(message, token),
                CancellationToken.None);

            if (response.FailureCount > 0)
            {
                var tokensToRemove = new List<Persistence.Entities.UserDeviceToken>();

                for (int i = 0; i < response.Responses.Count; i++)
                {
                    var res = response.Responses[i];
                    if (!res.IsSuccess && res.Exception != null)
                    {
                        if (res.Exception.MessagingErrorCode == MessagingErrorCode.Unregistered)
                        {
                            tokensToRemove.Add(tokens[i]);
                        }
                        else
                        {
                            _logger.LogWarning(res.Exception, "FCM send failed for token {Token}", tokens[i].FcmToken);
                        }
                    }
                }

                if (tokensToRemove.Any())
                {
                    _db.UserDeviceTokens.RemoveRange(tokensToRemove);
                    await _db.SaveChangesAsync(ct);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to dispatch FCM message for user {UserId}", userId);
            // We swallow the exception to ensure the parent HTTP request does not fail
        }
    }
}
