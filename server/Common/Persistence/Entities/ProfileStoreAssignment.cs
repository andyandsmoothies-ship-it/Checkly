namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Pure junction table tracking which stores an Area Manager is directly assigned to.
/// This replaces the implicit AreaId → Store.AreaId lookup with an explicit, auditable row.
/// Maps to: public.profile_store_assignments
/// PK strategy: Composite (ProfileId, StoreId) — no surrogate Id needed for a pure junction.
/// FK cascade: Profile delete → CASCADE; Store delete → RESTRICT.
/// </summary>
public sealed class ProfileStoreAssignment
{
    public Guid ProfileId { get; set; }
    public Guid StoreId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    // Navigation properties
    public Profile? Profile { get; set; }
    public Store? Store { get; set; }
}
