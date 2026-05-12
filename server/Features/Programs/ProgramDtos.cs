namespace Checkly.Api.Features.Programs;

/// <summary>
/// Request body for POST /api/programs.
/// storeIds: minimum 1 element required (validated in handler).
/// deadline: must be in the future (validated in handler).
/// title: max 200 chars | category: max 100 chars (enforced by DB column length).
/// </summary>
public record CreateProgramRequest(
    Guid TemplateId,
    Guid[] StoreIds,
    DateTimeOffset Deadline,
    string Category,
    string Title);

/// <summary>
/// Response body for POST /api/programs (201 Created).
/// </summary>
public record CreateProgramResponse(Guid ProgramId, int AssignmentCount);

/// <summary>
/// List item DTO for GET /api/programs.
/// Status is always the DB value ('active', 'completed', 'cancelled').
/// Overdue computation (deadline &lt; now &amp;&amp; status == 'pending') is done client-side.
/// </summary>
public record ProgramSummaryDto(
    Guid Id,
    string Title,
    string Category,
    DateTimeOffset Deadline,
    string Status,
    int TotalAssigned,
    DateTimeOffset CreatedAt);

// ── Slice 2A: SM Execution DTOs ──────────────────────────────────────────────

/// <summary>
/// A single assignment as seen by the Store Manager on GET /api/programs/assignments/my.
/// Status is computed: if DB=pending AND deadline &lt; now → return "overdue" in DTO.
/// </summary>
public record AssignmentSummaryDto(
    Guid Id,
    Guid ProgramId,
    string ProgramTitle,
    string Category,
    DateTimeOffset Deadline,
    string Status,
    DateTimeOffset CreatedAt,
    Guid? TemplateId = null);


public record ProgramAssignmentDetailDto(
    Guid Id,
    Guid ProgramId,
    Guid StoreId,
    string StoreName,
    string Status,
    DateTimeOffset Deadline,
    DateTimeOffset CreatedAt,
    string? RejectionComment,
    DateTimeOffset? VerifiedAt,
    Guid? LinkedSubmissionId,
    string? LinkedSubmissionStatus,
    decimal? LinkedSubmissionScore);

// ── Slice 4: HQ Rejection & Verification DTOs ────────────────────────────────

/// <summary>Request body for POST /api/programs/assignments/{id}/reject.</summary>
public record RejectRequest(string Reason);

// ── Slice 5: HQ Aggregation DTOs ───────────────────────────────────────────────

/// <summary>
/// Aggregated summary of a Program's assignments.
/// </summary>
public record ProgramSummaryResponse(
    int Total,
    int Pending,
    int Overdue,
    int Submitted,
    int NeedsRevision,
    int Verified,
    int CompletionRate);

// ── Slice 6: CRUD Parity DTOs ────────────────────────────────────────────────


/// <summary>
/// Request body for PUT /api/programs/{id}.
/// Only mutable fields: Title, Deadline, Category.
/// TemplateId and StoreIds are immutable after creation.
/// deadline: must be in the future (validated in handler).
/// title: cannot be empty (validated in handler).
/// </summary>
public record UpdateProgramRequest(
    string Title,
    DateTimeOffset Deadline,
    string Category);



