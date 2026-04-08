using Npgsql;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// BackgroundService that holds a dedicated Npgsql connection subscribed to
/// the 'pbac_invalidate' Postgres LISTEN channel. On notification, triggers
/// a full PbacDictionaryCache reload via InitializeAsync().
///
/// Reconnect strategy: exponential backoff (1s → 2s → 4s → 8s → 16s → 30s cap).
/// Cache retains last-known-good state during reconnect window.
/// Does NOT reset IsReady to false on disconnect — fail-open for reconnection.
/// </summary>
public sealed class PbacCacheListenerService(
    PbacDictionaryCache cache,
    IConfiguration configuration,
    ILogger<PbacCacheListenerService> logger,
    IServiceProvider sp) : BackgroundService
{
    // Exponential backoff intervals capped at 30s
    private static readonly TimeSpan[] BackoffIntervals =
    [
        TimeSpan.FromSeconds(1),
        TimeSpan.FromSeconds(2),
        TimeSpan.FromSeconds(4),
        TimeSpan.FromSeconds(8),
        TimeSpan.FromSeconds(16),
        TimeSpan.FromSeconds(30)  // cap
    ];

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var attempt = 0;

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var connStr = configuration.GetConnectionString("DefaultConnection")!;
                await using var conn = new NpgsqlConnection(connStr);
                await conn.OpenAsync(stoppingToken);

                // Issue the LISTEN command via a command object (Npgsql 10 API)
                await using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "LISTEN pbac_invalidate";
                    await cmd.ExecuteNonQueryAsync(stoppingToken);
                }

                logger.LogInformation("PBAC listener connected. Subscribed to 'pbac_invalidate'.");
                attempt = 0; // Reset backoff counter on successful connect

                while (!stoppingToken.IsCancellationRequested)
                {
                    // WaitAsync blocks until a notification arrives OR the token is cancelled.
                    // OperationCanceledException propagates on cancellation — caught by outer handler.
                    await conn.WaitAsync(stoppingToken);

                    logger.LogInformation("PBAC invalidation notification received. Reloading capability cache.");
                    await cache.InitializeAsync(sp);
                }
            }
            catch (OperationCanceledException)
            {
                // Graceful shutdown path — stoppingToken was cancelled.
                // Also catches OperationCanceledException from Task.Delay in the backoff sleep.
                // Exit the loop cleanly without logging an error.
                break;
            }
            catch (Exception ex)
            {
                var delay = BackoffIntervals[Math.Min(attempt, BackoffIntervals.Length - 1)];
                logger.LogWarning(ex,
                    "PBAC listener connection failed (attempt {Attempt}). Retrying in {DelaySeconds}s.",
                    ++attempt, delay.TotalSeconds);

                // Honour cancellation during the backoff sleep (Gap 2 — Sentinel's cancellation gap)
                await Task.Delay(delay, stoppingToken);
            }
        }

        logger.LogInformation("PBAC listener stopped.");
    }
}
