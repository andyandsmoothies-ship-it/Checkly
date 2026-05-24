using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/bod — retrieves the latest completed BOD report snapshot.
/// </summary>
public static class GetBodReport
{
    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        CancellationToken ct)
    {
        var snapshot = await db.Set<BodReportSnapshot>()
            .AsNoTracking()
            .OrderByDescending(s => s.Date)
            .FirstOrDefaultAsync(ct);

        if (snapshot == null)
        {
            return TypedResults.NotFound(new { error = "No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM." });
        }

        var jsonNode = System.Text.Json.Nodes.JsonNode.Parse(snapshot.Payload);
        if (jsonNode is System.Text.Json.Nodes.JsonObject jsonObject)
        {
            if (!jsonObject.ContainsKey("date"))
            {
                jsonObject["date"] = snapshot.Date.ToString("yyyy-MM-dd");
            }
            if (!jsonObject.ContainsKey("computedAt"))
            {
                jsonObject["computedAt"] = snapshot.ComputedAt.ToString("o");
            }
            if (!jsonObject.ContainsKey("status"))
            {
                jsonObject["status"] = snapshot.Status;
            }
            return TypedResults.Ok(jsonObject);
        }

        return TypedResults.Content(snapshot.Payload, "application/json");
    }
}
