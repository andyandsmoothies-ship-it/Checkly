using System.Threading.Channels;
using Microsoft.Extensions.Options;
using Npgsql;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// BackgroundService that holds a dedicated Npgsql connection subscribed to the
/// 'pbac_invalidate' Postgres LISTEN channel.
///
/// Architecture (Producer/Consumer via System.Threading.Channels):
///   - <see cref="ListenToDatabaseAsync"/>: Producer. Waits for Postgres NOTIFY and
///     writes a signal to the bounded channel (capacity 1, DropOldest).
///   - <see cref="ProcessDebounceAsync"/>: Consumer. Reads a signal, sleeps for
///     <see cref="PbacListenerOptions.DebounceWindowMs"/>, drains any subsequent
///     signals that arrived during the sleep, then executes exactly ONE cache reload.
///
/// Resync-on-Connect: On every successful connect/reconnect, InitializeAsync is called
/// unconditionally BEFORE entering the WaitAsync loop. This ensures no NOTIFY events
/// missed during a TCP drop are silently lost.
///
/// Reconnect strategy: exponential backoff (1s → 2s → 4s → 8s → 16s → 30s cap).
/// Cache retains last-known-good state during reconnect window.
/// </summary>
public sealed class PbacCacheListenerService : BackgroundService
{
    private readonly PbacDictionaryCache _cache;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PbacCacheListenerService> _logger;
    private readonly IServiceProvider _sp;
    private readonly PbacListenerOptions _options;

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

    /// <summary>
    /// Primary constructor used by the DI container.
    /// <paramref name="options"/> is nullable to allow the 4-param constructor used in unit tests
    /// (which don't inject IOptions) to delegate here with a null, falling back to defaults.
    /// </summary>
    public PbacCacheListenerService(
        PbacDictionaryCache cache,
        IConfiguration configuration,
        ILogger<PbacCacheListenerService> logger,
        IServiceProvider sp,
        IOptions<PbacListenerOptions>? options = null)
    {
        _cache = cache;
        _configuration = configuration;
        _logger = logger;
        _sp = sp;
        _options = options?.Value ?? new PbacListenerOptions();
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Bounded channel, capacity 1, DropOldest: TryWrite never blocks.
        // A burst of 50 NOTIFYs will result in the channel holding at most 1 item —
        // the Consumer wakes once, sleeps, drains, and calls InitializeAsync once.
        var channel = Channel.CreateBounded<bool>(new BoundedChannelOptions(1)
        {
            FullMode = BoundedChannelFullMode.DropOldest,
            SingleWriter = true,
            SingleReader = true
        });

        var debounceTask = ProcessDebounceAsync(channel.Reader, stoppingToken);
        var listenTask = ListenToDatabaseAsync(channel.Writer, stoppingToken);

        await Task.WhenAll(debounceTask, listenTask);

        _logger.LogInformation("PBAC listener stopped.");
    }

    /// <summary>
    /// Producer loop. Establishes a Postgres connection, issues LISTEN, performs a
    /// Resync-on-Connect reload, then forwards each incoming NOTIFY signal to the Channel.
    /// </summary>
    private async Task ListenToDatabaseAsync(ChannelWriter<bool> writer, CancellationToken ct)
    {
        var attempt = 0;

        while (!ct.IsCancellationRequested)
        {
            try
            {
                var connStr = _configuration.GetConnectionString("DefaultConnection")!;
                await using var conn = new NpgsqlConnection(connStr);
                await conn.OpenAsync(ct);

                await using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "LISTEN pbac_invalidate";
                    await cmd.ExecuteNonQueryAsync(ct);
                }

                _logger.LogInformation("PBAC listener connected. Subscribed to 'pbac_invalidate'.");
                attempt = 0;

                // [CRITICAL] Resync-on-Connect: reconcile any NOTIFYs missed while disconnected.
                // Called on EVERY connect — cold boot and reconnect alike.
                _logger.LogInformation("Executing unconditional Resync-on-Connect PBAC reload.");
                await _cache.InitializeAsync(_sp);

                while (!ct.IsCancellationRequested)
                {
                    await conn.WaitAsync(ct);
                    // Signal the debounce consumer — TryWrite never blocks even if channel is full.
                    writer.TryWrite(true);
                }
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                var delay = BackoffIntervals[Math.Min(attempt, BackoffIntervals.Length - 1)];
                var currentAttempt = ++attempt;

                if (currentAttempt >= 3)
                {
                    // Sustained failure threshold — triggers PBAC_CONSUMER_UNHEALTHY alert in Seq/Grafana.
                    _logger.LogError(ex,
                        "PBAC listener connection failed (attempt {Attempt}). Retrying in {DelaySeconds}s.",
                        currentAttempt, delay.TotalSeconds);
                }
                else
                {
                    _logger.LogWarning(ex,
                        "PBAC listener connection failed (attempt {Attempt}). Retrying in {DelaySeconds}s.",
                        currentAttempt, delay.TotalSeconds);
                }

                await Task.Delay(delay, ct);
            }
        }

        // Signal the consumer that no more items will arrive so it can exit cleanly.
        writer.Complete();
    }

    /// <summary>
    /// Consumer loop. Waits for a signal from the Channel, sleeps for the debounce window,
    /// drains any additional signals that arrived during the sleep, then executes one reload.
    /// </summary>
    private async Task ProcessDebounceAsync(ChannelReader<bool> reader, CancellationToken ct)
    {
        try
        {
            // Pre-declare drain variable outside the loop body to avoid CS0219 (unused variable).
            bool drained;

            await foreach (var _ in reader.ReadAllAsync(ct))
            {
                try
                {
                    // Signal: debounce window is now active—cache is intentionally stale.
                    _cache.IsRebuilding = true;

                    // Sleep for the debounce window — all subsequent signals pile into the channel
                    // (bounded to 1, DropOldest) and are collapsed by the drain below.
                    await Task.Delay(_options.DebounceWindowMs, ct);

                    // Drain: consume all signals that arrived during the sleep window.
                    // After this, the channel is empty — only one reload fires per burst.
                    while (reader.TryRead(out drained)) { }

                    _logger.LogInformation("PBAC debounce window elapsed. Reloading capability cache.");
                    await _cache.InitializeAsync(_sp);
                }
                finally
                {
                    // Always reset — even if InitializeAsync throws or CancellationToken fires.
                    _cache.IsRebuilding = false;
                }
            }
        }
        catch (OperationCanceledException) { /* Graceful shutdown */ }
    }
}
