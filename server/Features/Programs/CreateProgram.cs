using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// POST /api/programs — Create a Program and bulk-generate per-store ProgramAssignment rows.
/// Security: Requires programs:create capability (admin only).
/// Security: assigned_by_id is ALWAYS taken from the JWT — never from the request body.
/// </summary>
public static class CreateProgram
{
    public static async Task<IResult> HandleAsync(
        CreateProgramRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Guard: storeIds must have at least 1 element
        if (request.StoreIds.Length < 1)
            return TypedResults.BadRequest("At least one store must be specified.");

        // Guard: deadline must be in the future
        if (request.Deadline <= DateTimeOffset.UtcNow)
            return TypedResults.BadRequest("Deadline must be in the future.");

        // Guard: template must exist and be active
        var template = await db.Templates
            .SingleOrDefaultAsync(t => t.Id == request.TemplateId && t.IsActive, ct);

        if (template is null)
            return TypedResults.NotFound("Template not found or is inactive.");

        var createdById = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var now = DateTimeOffset.UtcNow;

        // Create the parent Program record
        var program = new ChecklyProgram
        {
            Id = Guid.NewGuid(),
            TemplateId = request.TemplateId,
            Title = request.Title,
            Category = request.Category,
            Deadline = request.Deadline,
            Status = "active",
            CreatedBy = createdById,
            CreatedAt = now,
            UpdatedAt = now
        };

        db.Programs.Add(program);

        // Bulk-create one ProgramAssignment per storeId
        // Security: AssignedById is captured from JWT, never from request body
        var assignments = request.StoreIds.Select(storeId => new ProgramAssignment
        {
            Id = Guid.NewGuid(),
            ProgramId = program.Id,
            StoreId = storeId,
            AssignedById = createdById,
            Status = "pending",
            CreatedAt = now,
            UpdatedAt = now
        }).ToList();

        db.ProgramAssignments.AddRange(assignments);

        // Audit trail: log program creation
        AuditLogger.Log(db, user, "program_created", "Program", program.Id,
            $"Program '{program.Title}' created with {assignments.Count} store assignment(s).",
            "/api/programs");

        await db.SaveChangesAsync(ct);

        return TypedResults.Created(
            $"/api/programs/{program.Id}",
            new CreateProgramResponse(program.Id, assignments.Count));
    }
}
