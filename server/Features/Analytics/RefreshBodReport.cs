using Microsoft.AspNetCore.Http;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// POST /api/analytics/bod/refresh — triggers an on-demand calculation of the BOD report.
/// </summary>
public static class RefreshBodReport
{
    public static async Task<IResult> HandleAsync(
        BodReportWorker worker,
        CancellationToken ct)
    {
        var result = await worker.TriggerOnDemandAsync(ct);

        return result.Outcome switch
        {
            TriggerResultOutcome.Success => TypedResults.Ok(new
            {
                status = "triggered",
                computedAt = result.ComputedAt
            }),

            TriggerResultOutcome.RateLimited => TypedResults.Json(new
            {
                status = "rate_limited",
                retryAfter = "15 min"
            }, statusCode: StatusCodes.Status429TooManyRequests),

            TriggerResultOutcome.Locked or _ => TypedResults.Conflict(new
            {
                error = "Another refresh job is already in progress."
            })
        };
    }
}
