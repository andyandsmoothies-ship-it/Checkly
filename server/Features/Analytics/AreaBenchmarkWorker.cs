using System.Diagnostics;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Checkly.Api.Features.Analytics;

public class BenchmarkWorkerOptions
{
    public int IntervalMinutes { get; set; } = 20;
}

public class AreaBenchmarkWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AreaBenchmarkWorker> _logger;
    private readonly BenchmarkWorkerOptions _options;
    private readonly DistributedLockManager _lockManager;

    public AreaBenchmarkWorker(
        IServiceProvider serviceProvider,
        ILogger<AreaBenchmarkWorker> logger,
        IOptions<BenchmarkWorkerOptions> options,
        DistributedLockManager lockManager)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _options = options.Value;
        _lockManager = lockManager;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AreaBenchmarkWorker started. Interval: {IntervalMinutes} minutes", _options.IntervalMinutes);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                await _lockManager.TryExecuteInLockAsync(db, "Checkly.AreaBenchmarkWorker", async (ct) =>
                {
                    var sw = Stopwatch.StartNew();
                    await AreaBenchmarkCalculator.RunForAllAreasAsync(db, _logger, ct);
                    sw.Stop();

                    _logger.LogInformation("AreaBenchmarkCalculator processed all areas in {ElapsedMilliseconds}ms", sw.ElapsedMilliseconds);
                }, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Graceful shutdown
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while calculating area benchmarks.");
            }

            // Sleep for the configured interval
            await Task.Delay(TimeSpan.FromMinutes(_options.IntervalMinutes), stoppingToken);
        }

        _logger.LogInformation("AreaBenchmarkWorker stopping.");
    }
}
