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
    public DbSet<ProfileStoreAssignment> ProfileStoreAssignments => Set<ProfileStoreAssignment>();
    public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();
    public DbSet<ProvinceBenchmarkSnapshot> ProvinceBenchmarkSnapshots => Set<ProvinceBenchmarkSnapshot>();
    public DbSet<BodReportSnapshot> BodReportSnapshots => Set<BodReportSnapshot>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        base.OnConfiguring(optionsBuilder);
        optionsBuilder.ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
