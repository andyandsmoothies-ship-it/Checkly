using System;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Polly;
using Polly.Retry;

namespace Checkly.Api.Common.Services;

public class OutboxBackgroundService(
    IServiceProvider serviceProvider,
    ILogger<OutboxBackgroundService> logger) : BackgroundService
{
    // SA-5: Classify deterministic failures that must NOT be retried.
    // JsonException/FormatException/ArgumentException indicate a malformed payload
    // that will never succeed on retry — retrying them causes a 14-second burn per message.
    private static bool IsFatalMessageError(Exception ex) =>
        ex is System.Text.Json.JsonException ||
        ex is FormatException ||
        ex is ArgumentException;

    private readonly ResiliencePipeline _retryPipeline = new ResiliencePipelineBuilder()
        .AddRetry(new RetryStrategyOptions
        {
            MaxRetryAttempts = 3,
            BackoffType = DelayBackoffType.Exponential,
            Delay = TimeSpan.FromSeconds(2),
            // Only retry transient exceptions — not deterministic parse/format failures.
            ShouldHandle = new PredicateBuilder().Handle<Exception>(ex => !IsFatalMessageError(ex)),
            OnRetry = args =>
            {
                logger.LogWarning(args.Outcome.Exception, "Error processing outbox message. Retrying in {Delay}...", args.RetryDelay);
                return ValueTask.CompletedTask;
            }
        })
        .Build();

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("OutboxBackgroundService is starting.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOutboxMessagesAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "An unhandled exception occurred in OutboxBackgroundService.");
            }

            // Delay between polls
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }

        logger.LogInformation("OutboxBackgroundService is stopping.");
    }

    private async Task ProcessOutboxMessagesAsync(CancellationToken stoppingToken)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Fetch unprocessed messages
        var messages = await db.OutboxMessages
            .Where(m => m.ProcessedAt == null && m.Error == null)
            .OrderBy(m => m.CreatedAt)
            .Take(50)
            .ToListAsync(stoppingToken);

        if (messages.Count == 0)
        {
            return;
        }

        foreach (var message in messages)
        {
            await ProcessMessageWithRetryAsync(scope, db, message, stoppingToken);
        }
    }

    private async Task ProcessMessageWithRetryAsync(
        IServiceScope scope,
        AppDbContext db,
        OutboxMessage message,
        CancellationToken stoppingToken)
    {
        try
        {
            await _retryPipeline.ExecuteAsync(async ct =>
            {
                if (message.Type == "Notification")
                {
                    var fcmService = scope.ServiceProvider.GetRequiredService<IFcmDispatchService>();

                    using var doc = JsonDocument.Parse(message.Payload);
                    if (doc.RootElement.TryGetProperty("UserId", out var userIdElement) &&
                        userIdElement.TryGetGuid(out var userId))
                    {
                        await fcmService.DispatchSyncNeededAsync(userId);
                    }
                }
                else
                {
                    // SC-2: Unknown message types must fail loudly, not silently succeed.
                    // Future types ("Email", "Webhook") that lack dispatch logic land here
                    // and produce a structured log + error record instead of a phantom ProcessedAt.
                    logger.LogWarning(
                        "OutboxBackgroundService: unhandled message type '{Type}' (id: {Id}). Writing error.",
                        message.Type, message.Id);
                    message.Error = $"Unhandled message type: {message.Type}";
                }
            }, stoppingToken);

            message.ProcessedAt = DateTimeOffset.UtcNow;
            message.Error = null;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to process outbox message {MessageId} after retries.", message.Id);
            message.Error = ex.Message;
        }

        // Save changes incrementally so we don't hold up other messages
        await db.SaveChangesAsync(stoppingToken);
    }
}
