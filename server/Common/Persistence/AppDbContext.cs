using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common.Persistence;

/// <summary>
/// Central EF Core DbContext for Checkly.
/// Extends IdentityDbContext to integrate ASP.NET Identity (AppUser, roles)
/// alongside the 10 core domain entities.
/// Table names use snake_case to match the live database.
/// </summary>
public sealed class AppDbContext(DbContextOptions<AppDbContext> options)
    : IdentityDbContext<AppUser, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<Store> Stores => Set<Store>();
    public DbSet<Profile> Profiles => Set<Profile>();
    public DbSet<UserRole> AppUserRoles => Set<UserRole>();
    public DbSet<Template> Templates => Set<Template>();
    public DbSet<Group> Groups => Set<Group>();
    public DbSet<Criterion> Criteria => Set<Criterion>();
    public DbSet<Submission> Submissions => Set<Submission>();
    public DbSet<Answer> Answers => Set<Answer>();
    public DbSet<ActionPlan> ActionPlans => Set<ActionPlan>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<SystemLog> SystemLogs => Set<SystemLog>();
    public DbSet<Area> Areas => Set<Area>();
    public DbSet<UserGroup> UserGroups => Set<UserGroup>();
    public DbSet<UserGroupMember> UserGroupMembers => Set<UserGroupMember>();
    public DbSet<TemplateAssignment> TemplateAssignments => Set<TemplateAssignment>();
    public DbSet<SubmissionSectionScore> SubmissionSectionScores => Set<SubmissionSectionScore>();
    public DbSet<StoreAnalyticsSnapshot> StoreAnalyticsSnapshots => Set<StoreAnalyticsSnapshot>();
    public DbSet<RoleCapability> RoleCapabilities => Set<RoleCapability>();
    public DbSet<GlobalRisk> GlobalRisks => Set<GlobalRisk>();
    public DbSet<SubmissionRisk> SubmissionRisks => Set<SubmissionRisk>();
    public DbSet<UserDeviceToken> UserDeviceTokens => Set<UserDeviceToken>();
    public DbSet<ChecklyProgram> Programs => Set<ChecklyProgram>();
    public DbSet<ProgramAssignment> ProgramAssignments => Set<ProgramAssignment>();
    public DbSet<ProgramEvidence> ProgramEvidence => Set<ProgramEvidence>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        ConfigureIdentityRelationships(modelBuilder);
        ConfigureStore(modelBuilder);
        ConfigureProfile(modelBuilder);
        ConfigureUserRole(modelBuilder);
        ConfigureTemplate(modelBuilder);
        ConfigureGroup(modelBuilder);
        ConfigureCriterion(modelBuilder);
        ConfigureSubmission(modelBuilder);
        ConfigureAnswer(modelBuilder);
        ConfigureActionPlan(modelBuilder);
        ConfigureNotification(modelBuilder);
        ConfigureSystemLog(modelBuilder);
        ConfigureArea(modelBuilder);
        ConfigureUserGroup(modelBuilder);
        ConfigureUserGroupMember(modelBuilder);
        ConfigureTemplateAssignment(modelBuilder);
        ConfigureSubmissionSectionScore(modelBuilder);
        ConfigureStoreAnalyticsSnapshot(modelBuilder);
        ConfigureRoleCapability(modelBuilder);
        ConfigureGlobalRisk(modelBuilder);
        ConfigureSubmissionRisk(modelBuilder);
        ConfigureUserDeviceToken(modelBuilder);
        ConfigureProgram(modelBuilder);
        ConfigureProgramAssignment(modelBuilder);
        ConfigureProgramEvidence(modelBuilder);
    }

    private static void ConfigureStore(ModelBuilder mb)
    {
        mb.Entity<Store>(e =>
        {
            e.ToTable("stores");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Name).HasColumnName("name").IsRequired();
            e.Property(x => x.Address).HasColumnName("address");
            e.Property(x => x.AreaId).HasColumnName("area_id");
            e.Property(x => x.GpsLat).HasColumnName("gps_lat");
            e.Property(x => x.GpsLng).HasColumnName("gps_lng");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);

            // FK: Store → Area
            e.HasOne(x => x.Area)
                .WithMany(a => a.Stores)
                .HasForeignKey(x => x.AreaId)
                .OnDelete(DeleteBehavior.SetNull);

            // Performance indexes
            e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        });
    }

    private static void ConfigureProfile(ModelBuilder mb)
    {
        mb.Entity<Profile>(e =>
        {
            e.ToTable("profiles");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.FullName).HasColumnName("full_name");
            e.Property(x => x.Email).HasColumnName("email");
            e.Property(x => x.AvatarUrl).HasColumnName("avatar_url");
            e.Property(x => x.StoreId).HasColumnName("store_id");
            e.Property(x => x.AreaId).HasColumnName("area_id");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

            e.HasOne(x => x.Store)
                .WithMany(s => s.Profiles)
                .HasForeignKey(x => x.StoreId)
                .OnDelete(DeleteBehavior.SetNull);

            // FK: Profile → Area
            e.HasOne(x => x.Area)
                .WithMany(a => a.Profiles)
                .HasForeignKey(x => x.AreaId)
                .OnDelete(DeleteBehavior.SetNull);

            // Performance indexes
            e.HasIndex(x => x.StoreId);
            e.HasIndex(x => x.AreaId);
        });
    }

    private static void ConfigureUserRole(ModelBuilder mb)
    {
        mb.Entity<UserRole>(e =>
        {
            e.ToTable("user_roles");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id").IsRequired();
            e.Property(x => x.Role).HasColumnName("role").IsRequired();
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        });
    }

    private static void ConfigureTemplate(ModelBuilder mb)
    {
        mb.Entity<Template>(e =>
        {
            e.ToTable("templates");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Title).HasColumnName("title").IsRequired();
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.Type).HasColumnName("type").IsRequired();
            e.Property(x => x.Version).HasColumnName("version").HasDefaultValue(1);
            e.Property(x => x.ScoringLogicConfig).HasColumnName("scoring_logic_config").HasColumnType("jsonb");
            e.Property(x => x.DisplayNoun).HasColumnName("display_noun");
            e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);
            e.Property(x => x.CreatedBy).HasColumnName("created_by");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

            // Optimistic concurrency via PostgreSQL system column xmin
            e.Property(x => x.RowVersion)
                .HasColumnName("xmin")
                .HasColumnType("xid")
                .ValueGeneratedOnAddOrUpdate()
                .IsConcurrencyToken();

            // Performance indexes
            e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        });
    }

    private static void ConfigureGroup(ModelBuilder mb)
    {
        mb.Entity<Group>(e =>
        {
            e.ToTable("groups");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.TemplateId).HasColumnName("template_id").IsRequired();
            e.Property(x => x.Title).HasColumnName("title").IsRequired();
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.Weight).HasColumnName("weight");
            e.Property(x => x.MaxDeductionPoints).HasColumnName("max_deduction_points");
            e.Property(x => x.MinusPerFault).HasColumnName("minus_per_fault");
            e.Property(x => x.OrderIndex).HasColumnName("order_index").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.ParentId).HasColumnName("parent_id");
            e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
            e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);

            e.HasOne(x => x.Template)
                .WithMany(t => t.Groups)
                .HasForeignKey(x => x.TemplateId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.Parent)
                .WithMany(g => g.Children)
                .HasForeignKey(x => x.ParentId)
                .OnDelete(DeleteBehavior.Restrict);

            // Performance indexes
            e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        });
    }

    private static void ConfigureCriterion(ModelBuilder mb)
    {
        mb.Entity<Criterion>(e =>
        {
            e.ToTable("criteria");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.GroupId).HasColumnName("group_id").IsRequired();
            e.Property(x => x.Label).HasColumnName("label").IsRequired();
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.InputType).HasColumnName("input_type").IsRequired();
            e.Property(x => x.PointsWeight).HasColumnName("points_weight").HasDefaultValue(1.0m);
            e.Property(x => x.IsCcp).HasColumnName("is_ccp").HasDefaultValue(false);
            e.Property(x => x.IsRisk).HasColumnName("is_risk").HasDefaultValue(false);
            e.Property(x => x.MinusImpact).HasColumnName("minus_impact");
            e.Property(x => x.MaxDeductionPoints).HasColumnName("max_deduction_points");
            e.Property(x => x.OrderIndex).HasColumnName("order_index").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
            e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);

            e.HasOne(x => x.Group)
                .WithMany(g => g.Criteria)
                .HasForeignKey(x => x.GroupId)
                .OnDelete(DeleteBehavior.Cascade);

            // Performance indexes
            e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        });
    }

    /// <summary>
    /// Configures the Submission entity mapping.
    /// WARNING: Never add a hard-delete endpoint for submissions.
    /// Submissions are immutable audit records — soft-delete is not applicable.
    /// </summary>
    private static void ConfigureSubmission(ModelBuilder mb)
    {
        mb.Entity<Submission>(e =>
        {
            e.ToTable("submissions");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.TemplateId).HasColumnName("template_id");
            e.Property(x => x.AuditorId).HasColumnName("auditor_id");
            e.Property(x => x.StoreId).HasColumnName("store_id");
            e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("draft");
            e.Property(x => x.ScoringMode).HasColumnName("scoring_mode").HasDefaultValue("penalty");
            e.Property(x => x.TotalScore).HasColumnName("total_score");
            e.Property(x => x.SectionScores).HasColumnName("section_scores").HasColumnType("jsonb");
            e.Property(x => x.GpsLat).HasColumnName("gps_lat");
            e.Property(x => x.GpsLng).HasColumnName("gps_lng");
            e.Property(x => x.GpsVerifiedAt).HasColumnName("gps_verified_at");
            e.Property(x => x.Notes).HasColumnName("notes");
            e.Property(x => x.ScheduledAt).HasColumnName("scheduled_at");
            e.Property(x => x.CompletedAt).HasColumnName("completed_at");
            e.Property(x => x.ApprovedBy).HasColumnName("approved_by");
            e.Property(x => x.ApprovedAt).HasColumnName("approved_at");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.StartedAt).HasColumnName("started_at");
            e.Property(x => x.AuditorName).HasColumnName("auditor_name");
            e.Property(x => x.AuditorEmail).HasColumnName("auditor_email");
            e.Property(x => x.StoreName).HasColumnName("store_name");
            e.Property(x => x.TemplateTitle).HasColumnName("template_title");
            e.Property(x => x.TemplateType).HasColumnName("template_type");
            e.Property(x => x.DisplayNoun).HasColumnName("display_noun");
            e.Property(x => x.ApproverName).HasColumnName("approver_name");
            e.Property(x => x.ReviewStatus).HasColumnName("review_status");
            e.Property(x => x.IdempotencyKey).HasColumnName("idempotency_key");
            e.Property(x => x.TemplateSnapshot).HasColumnName("template_snapshot").HasColumnType("jsonb");
            e.Property(x => x.TemplateVersion).HasColumnName("template_version");
            e.Property(x => x.RawEarnedPoints).HasColumnName("raw_earned_points");
            e.Property(x => x.RawMaxPoints).HasColumnName("raw_max_points");
            e.Property(x => x.IsWeighted).HasColumnName("is_weighted");
            e.Property(x => x.VoidReason).HasColumnName("void_reason");
            e.Property(x => x.VoidedAt).HasColumnName("voided_at");

            // Optimistic concurrency via PostgreSQL system column xmin
            // Guards against TOCTOU race on concurrent FinalizeSubmission requests (F7)
            e.Property(x => x.RowVersion)
                .HasColumnName("xmin")
                .HasColumnType("xid")
                .ValueGeneratedOnAddOrUpdate()
                .IsConcurrencyToken();

            e.HasIndex(x => x.IdempotencyKey)
                .IsUnique()
                .HasFilter("idempotency_key IS NOT NULL");

            // Performance indexes
            e.HasIndex(x => x.AuditorId);
            e.HasIndex(x => x.CreatedAt).IsDescending();
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
            e.HasIndex(x => new { x.Status, x.ReviewStatus });
            e.HasIndex(x => new { x.StoreId, x.CreatedAt }).IsDescending(false, true);
            e.HasIndex(x => new { x.TemplateId, x.ScoringMode });

            e.HasOne(x => x.Template)
                .WithMany(t => t.Submissions)
                .HasForeignKey(x => x.TemplateId)
                .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(x => x.Store)
                .WithMany(s => s.Submissions)
                .HasForeignKey(x => x.StoreId)
                .OnDelete(DeleteBehavior.SetNull);
        });
    }

    private static void ConfigureAnswer(ModelBuilder mb)
    {
        mb.Entity<Answer>(e =>
        {
            e.ToTable("answers");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.SubmissionId).HasColumnName("submission_id");
            e.Property(x => x.CriteriaId).HasColumnName("criteria_id");
            e.Property(x => x.Value).HasColumnName("value");
            e.Property(x => x.NumericValue).HasColumnName("numeric_value");
            e.Property(x => x.Note).HasColumnName("note");
            e.Property(x => x.PhotoUrl).HasColumnName("photo_url");
            e.Property(x => x.PhotoMetadata).HasColumnName("photo_metadata").HasColumnType("jsonb");
            e.Property(x => x.IsRepeatedError).HasColumnName("is_repeated_error").HasDefaultValue(false);
            e.Property(x => x.IsCcp).HasColumnName("is_ccp").HasDefaultValue(false);
            e.Property(x => x.IsRisk).HasColumnName("is_risk").HasDefaultValue(false);
            e.Property(x => x.IsFailure).HasColumnName("is_failure").HasDefaultValue(false);
            e.Property(x => x.RepeatedFaults).HasColumnName("repeated_faults").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
            e.Property(x => x.CriteriaLabel).HasColumnName("criteria_label");

            e.HasOne(x => x.Submission)
                .WithMany(s => s.Answers)
                .HasForeignKey(x => x.SubmissionId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.Criterion)
                .WithMany(c => c.Answers)
                .HasForeignKey(x => x.CriteriaId)
                .OnDelete(DeleteBehavior.SetNull);

            // Composite index for fast Top Failures analytics query (concept brief Phase A mandate)
            e.HasIndex(x => new { x.IsFailure, x.CriteriaId })
                .HasDatabaseName("IX_answers_is_failure_criteria_id");
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        });
    }

    /// <summary>
    /// Configures the ActionPlan entity mapping.
    /// WARNING: Never add a hard-delete endpoint for action plans.
    /// Action plans are compliance records — they must be preserved for audit trails.
    /// </summary>
    private static void ConfigureActionPlan(ModelBuilder mb)
    {
        mb.Entity<ActionPlan>(e =>
        {
            e.ToTable("action_plans");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.AnswerId).HasColumnName("answer_id");
            e.Property(x => x.SubmissionId).HasColumnName("submission_id");
            e.Property(x => x.StoreId).HasColumnName("store_id");
            e.Property(x => x.StoreManagerId).HasColumnName("store_manager_id");
            e.Property(x => x.CriteriaLabel).HasColumnName("criteria_label").IsRequired();
            e.Property(x => x.GroupTitle).HasColumnName("group_title").IsRequired();
            e.Property(x => x.PlanDescription).HasColumnName("plan_description");
            e.Property(x => x.EvidencePhotoUrl).HasColumnName("evidence_photo_url");
            e.Property(x => x.EvidenceNote).HasColumnName("evidence_note");
            e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("open");
            e.Property(x => x.Deadline).HasColumnName("deadline");
            e.Property(x => x.ClosedAt).HasColumnName("closed_at");
            e.Property(x => x.VerifiedBy).HasColumnName("verified_by");
            e.Property(x => x.VerifiedAt).HasColumnName("verified_at");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.RootCause).HasColumnName("root_cause");
            e.Property(x => x.CorrectionPlan).HasColumnName("correction_plan");
            e.Property(x => x.StoreName).HasColumnName("store_name");
            e.Property(x => x.StoreManagerName).HasColumnName("store_manager_name");
            e.Property(x => x.VerifierName).HasColumnName("verifier_name");
            e.Property(x => x.EvidenceSubmittedAt).HasColumnName("evidence_submitted_at");
            e.Property(x => x.EvidenceSubmittedByName).HasColumnName("evidence_submitted_by_name");

            e.HasOne(x => x.Answer)
                .WithMany(a => a.ActionPlans)
                .HasForeignKey(x => x.AnswerId)
                .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(x => x.Submission)
                .WithMany(s => s.ActionPlans)
                .HasForeignKey(x => x.SubmissionId)
                .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(x => x.Store)
                .WithMany(s => s.ActionPlans)
                .HasForeignKey(x => x.StoreId)
                .OnDelete(DeleteBehavior.SetNull);

            // Unique constraint: prevents duplicate APs for the same (submission, answer) under race conditions
            e.HasIndex(x => new { x.SubmissionId, x.AnswerId })
                .IsUnique()
                .HasFilter("submission_id IS NOT NULL AND answer_id IS NOT NULL");

            // Performance indexes
            e.HasIndex(x => new { x.StoreId, x.Status });
            e.HasIndex(x => x.Deadline);
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        });
    }

    private static void ConfigureNotification(ModelBuilder mb)
    {
        mb.Entity<Notification>(e =>
        {
            e.ToTable("notifications");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id").IsRequired();
            e.Property(x => x.Type).HasColumnName("type").IsRequired();
            e.Property(x => x.Title).HasColumnName("title").IsRequired();
            e.Property(x => x.Message).HasColumnName("message");
            e.Property(x => x.ReadAt).HasColumnName("read_at");
            e.Property(x => x.ActionUrl).HasColumnName("action_url");
            e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            // Performance indexes
            e.HasIndex(x => new { x.UserId, x.CreatedAt });
            e.HasIndex(x => new { x.UserId, x.Type });
        });
    }

    private static void ConfigureIdentityRelationships(ModelBuilder mb)
    {
        // Profile ↔ AppUser: logically 1:1 via matching Id
        // NOT enforced by FK — Profiles can exist without AppUser rows
        // (e.g., test seeding, offline-created profiles, SQL migration data)
        // The registration flow ensures both records are created together.
        mb.Entity<AppUser>().Ignore(u => u.Profile);

        // F2 Fix: snake_case column mapping for the revocation timestamp.
        // EF Identity would default to "InvalidateTokensBefore" (PascalCase) without this.
        mb.Entity<AppUser>()
            .Property(u => u.InvalidateTokensBefore)
            .HasColumnName("invalidate_tokens_before");

        // UserRole → AppUser: many-to-1
        mb.Entity<UserRole>(e =>
        {
            e.HasOne<AppUser>()
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }

    private static void ConfigureSystemLog(ModelBuilder mb)
    {
        mb.Entity<SystemLog>(e =>
        {
            e.ToTable("system_logs");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Action).HasColumnName("action").IsRequired();
            e.Property(x => x.Category).HasColumnName("category").IsRequired();
            e.Property(x => x.Message).HasColumnName("message");
            e.Property(x => x.Path).HasColumnName("path");
            e.Property(x => x.Level).HasColumnName("level").HasDefaultValue("info");
            e.Property(x => x.EntityType).HasColumnName("entity_type");
            e.Property(x => x.EntityId).HasColumnName("entity_id");
            e.Property(x => x.TraceId).HasColumnName("trace_id");
            e.Property(x => x.UserEmail).HasColumnName("user_email");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            // Performance indexes
            e.HasIndex(x => x.CreatedAt).IsDescending();
            e.HasIndex(x => new { x.EntityType, x.EntityId });
        });
    }
    private static void ConfigureArea(ModelBuilder mb)
    {
        mb.Entity<Area>(e =>
        {
            e.ToTable("areas");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Name).HasColumnName("name").IsRequired();
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

            // Performance indexes
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync parity
        });
    }

    private static void ConfigureUserGroup(ModelBuilder mb)
    {
        mb.Entity<UserGroup>(e =>
        {
            e.ToTable("user_groups");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Name).HasColumnName("name").IsRequired();
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        });
    }

    private static void ConfigureUserGroupMember(ModelBuilder mb)
    {
        mb.Entity<UserGroupMember>(e =>
        {
            e.ToTable("user_group_members");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserGroupId).HasColumnName("user_group_id").IsRequired();
            e.Property(x => x.ProfileId).HasColumnName("profile_id").IsRequired();
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            e.HasIndex(x => new { x.UserGroupId, x.ProfileId }).IsUnique();

            e.HasOne(x => x.UserGroup)
                .WithMany(g => g.Members)
                .HasForeignKey(x => x.UserGroupId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.Profile)
                .WithMany()
                .HasForeignKey(x => x.ProfileId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }

    private static void ConfigureTemplateAssignment(ModelBuilder mb)
    {
        mb.Entity<TemplateAssignment>(e =>
        {
            e.ToTable("template_assignments");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.TemplateId).HasColumnName("template_id").IsRequired();
            e.Property(x => x.UserGroupId).HasColumnName("user_group_id").IsRequired();
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            e.HasIndex(x => new { x.TemplateId, x.UserGroupId }).IsUnique();

            e.HasOne(x => x.Template)
                .WithMany(t => t.Assignments)
                .HasForeignKey(x => x.TemplateId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.UserGroup)
                .WithMany(g => g.Assignments)
                .HasForeignKey(x => x.UserGroupId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }

    private static void ConfigureSubmissionSectionScore(ModelBuilder mb)
    {
        mb.Entity<SubmissionSectionScore>(e =>
        {
            e.ToTable("submission_section_scores");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.SubmissionId).HasColumnName("submission_id").IsRequired();
            e.Property(x => x.StoreId).HasColumnName("store_id");
            e.Property(x => x.TemplateId).HasColumnName("template_id");
            e.Property(x => x.SectionTitle).HasColumnName("section_title").IsRequired();
            e.Property(x => x.Score).HasColumnName("score");
            e.Property(x => x.MaxScore).HasColumnName("max_score");
            e.Property(x => x.Ratio).HasColumnName("ratio");
            e.Property(x => x.IsCcpFailed).HasColumnName("is_ccp_failed").HasDefaultValue(false);
            e.Property(x => x.Weight).HasColumnName("weight");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            e.HasOne(x => x.Submission)
                .WithMany()
                .HasForeignKey(x => x.SubmissionId)
                .OnDelete(DeleteBehavior.Cascade);

            // Performance indexes
            e.HasIndex(x => x.SubmissionId);
            e.HasIndex(x => new { x.StoreId, x.SectionTitle });
        });
    }

    private static void ConfigureStoreAnalyticsSnapshot(ModelBuilder mb)
    {
        mb.Entity<StoreAnalyticsSnapshot>(e =>
        {
            e.ToTable("store_analytics_snapshot");
            e.HasKey(x => x.StoreId);
            e.Property(x => x.StoreId).HasColumnName("store_id");
            e.Property(x => x.AvgScore30d).HasColumnName("avg_score_30d");
            e.Property(x => x.TotalAudits30d).HasColumnName("total_audits_30d");
            e.Property(x => x.OpenActionPlans).HasColumnName("open_action_plans").HasDefaultValue(0);
            e.Property(x => x.OverdueActionPlans).HasColumnName("overdue_action_plans").HasDefaultValue(0);
            e.Property(x => x.LastAuditScore).HasColumnName("last_audit_score");
            e.Property(x => x.LastAuditAt).HasColumnName("last_audit_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

            e.HasOne(x => x.Store)
                .WithOne()
                .HasForeignKey<StoreAnalyticsSnapshot>(x => x.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }

    private static void ConfigureRoleCapability(ModelBuilder mb)
    {
        mb.Entity<RoleCapability>(e =>
        {
            e.ToTable("role_capabilities");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Role).HasColumnName("role").IsRequired().HasMaxLength(50);
            e.Property(x => x.Capability).HasColumnName("capability").IsRequired().HasMaxLength(100);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            // Composite unique constraint: one capability string per role
            e.HasIndex(x => new { x.Role, x.Capability })
                .IsUnique()
                .HasDatabaseName("UX_role_capabilities_role_capability");

            // Performance index: cache warm-up queries by role
            e.HasIndex(x => x.Role)
                .HasDatabaseName("IX_role_capabilities_role");
        });
    }

    private static void ConfigureGlobalRisk(ModelBuilder mb)
    {
        mb.Entity<GlobalRisk>(e =>
        {
            e.ToTable("global_risks");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Label).HasColumnName("label").IsRequired().HasMaxLength(200);
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

            // Performance indexes
            e.HasIndex(x => x.UpdatedAt); // For offline delta sync
            e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
        });
    }

    private static void ConfigureSubmissionRisk(ModelBuilder mb)
    {
        mb.Entity<SubmissionRisk>(e =>
        {
            e.ToTable("submission_risks");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.SubmissionId).HasColumnName("submission_id").IsRequired();
            e.Property(x => x.GlobalRiskId).HasColumnName("global_risk_id").IsRequired();
            e.Property(x => x.TriggeredById).HasColumnName("triggered_by_id");
            e.Property(x => x.Note).HasColumnName("note");
            e.Property(x => x.TriggeredAt).HasColumnName("triggered_at");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            // FK: submission_id → submissions (cascade: deleting submission deletes its risks)
            e.HasOne(x => x.Submission)
                .WithMany(s => s.SubmissionRisks)
                .HasForeignKey(x => x.SubmissionId)
                .OnDelete(DeleteBehavior.Cascade);

            // FK: global_risk_id → global_risks (restrict: cannot delete a risk that has been triggered)
            e.HasOne(x => x.GlobalRisk)
                .WithMany(r => r.SubmissionRisks)
                .HasForeignKey(x => x.GlobalRiskId)
                .OnDelete(DeleteBehavior.Restrict);

            // Unique constraint: prevents double-triggering same risk on a submission
            e.HasIndex(x => new { x.SubmissionId, x.GlobalRiskId }).IsUnique();

            // Performance indexes
            e.HasIndex(x => x.SubmissionId);
            e.HasIndex(x => x.GlobalRiskId);
        });
    }

    private static void ConfigureUserDeviceToken(ModelBuilder mb)
    {
        mb.Entity<UserDeviceToken>(e =>
        {
            e.ToTable("user_device_tokens");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id").IsRequired();
            e.Property(x => x.FcmToken).HasColumnName("fcm_token").IsRequired();
            e.Property(x => x.Platform).HasColumnName("platform").IsRequired();
            e.Property(x => x.LastUsedAt).HasColumnName("last_used_at").HasDefaultValueSql("now()");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            e.HasIndex(x => new { x.UserId, x.FcmToken }).IsUnique();
            e.HasIndex(x => x.UserId); // For FCM dispatch queries
        });
    }

    private static void ConfigureProgram(ModelBuilder mb)
    {
        mb.Entity<ChecklyProgram>(e =>
        {
            e.ToTable("programs");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.TemplateId).HasColumnName("template_id").IsRequired();
            e.Property(x => x.Title).HasColumnName("title").IsRequired().HasMaxLength(200);
            e.Property(x => x.Category).HasColumnName("category").IsRequired().HasMaxLength(100);
            e.Property(x => x.Deadline).HasColumnName("deadline").IsRequired();
            e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("active");
            e.Property(x => x.CreatedBy).HasColumnName("created_by").IsRequired();
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

            // Optimistic concurrency via PostgreSQL system column xmin
            e.Property(x => x.RowVersion)
                .HasColumnName("xmin")
                .HasColumnType("xid")
                .ValueGeneratedOnAddOrUpdate()
                .IsConcurrencyToken();

            // FK: Program → Template (restrict: cannot delete a template that has programs)
            e.HasOne(x => x.Template)
                .WithMany()
                .HasForeignKey(x => x.TemplateId)
                .OnDelete(DeleteBehavior.Restrict);

            // Performance indexes
            e.HasIndex(x => x.Status);
            e.HasIndex(x => x.Deadline);
            e.HasIndex(x => x.CreatedBy);
            e.HasIndex(x => x.CreatedAt).IsDescending();
        });
    }

    private static void ConfigureProgramAssignment(ModelBuilder mb)
    {
        mb.Entity<ProgramAssignment>(e =>
        {
            e.ToTable("program_assignments");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.ProgramId).HasColumnName("program_id").IsRequired();
            e.Property(x => x.StoreId).HasColumnName("store_id").IsRequired();
            e.Property(x => x.AssignedById).HasColumnName("assigned_by_id").IsRequired();
            e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("pending");
            e.Property(x => x.CompletedAt).HasColumnName("completed_at");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.RejectionComment).HasColumnName("rejection_comment");
            e.Property(x => x.VerifiedAt).HasColumnName("verified_at");

            // Optimistic concurrency via PostgreSQL system column xmin
            e.Property(x => x.RowVersion)
                .HasColumnName("xmin")
                .HasColumnType("xid")
                .ValueGeneratedOnAddOrUpdate()
                .IsConcurrencyToken();

            // FK: ProgramAssignment → Program (cascade: deleting a program deletes its assignments)
            e.HasOne(x => x.Program)
                .WithMany(p => p.Assignments)
                .HasForeignKey(x => x.ProgramId)
                .OnDelete(DeleteBehavior.Cascade);

            // FK: ProgramAssignment → Store (restrict: cannot delete a store that has assignments)
            e.HasOne(x => x.Store)
                .WithMany()
                .HasForeignKey(x => x.StoreId)
                .OnDelete(DeleteBehavior.Restrict);

            // Performance indexes: core query patterns
            e.HasIndex(x => new { x.ProgramId, x.Status });
            e.HasIndex(x => new { x.StoreId, x.Status });
            e.HasIndex(x => new { x.ProgramId, x.CreatedAt }).IsDescending(false, true);
            e.HasIndex(x => x.AssignedById);
        });
    }


    private static void ConfigureProgramEvidence(ModelBuilder mb)
    {
        mb.Entity<ProgramEvidence>(e =>
        {
            e.ToTable("program_evidence");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.AssignmentId).HasColumnName("assignment_id").IsRequired();
            e.Property(x => x.CriteriaId).HasColumnName("criteria_id");
            e.Property(x => x.CriteriaLabel).HasColumnName("criteria_label").HasMaxLength(500);
            e.Property(x => x.Value).HasColumnName("value").IsRequired();
            e.Property(x => x.PhotoLocalKey).HasColumnName("photo_local_key");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

            // FK: ProgramEvidence → ProgramAssignment (cascade: deleting an assignment deletes its evidence)
            e.HasOne(x => x.Assignment)
                .WithMany()
                .HasForeignKey(x => x.AssignmentId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasIndex(x => x.AssignmentId);
        });
    }
}
