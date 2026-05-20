using System.Text;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Auth;
using Checkly.Api.Features.ActionPlans;
using Checkly.Api.Features.Notifications;
using Checkly.Api.Features.Photos;
using Checkly.Api.Features.Stores;
using Checkly.Api.Features.Submissions;
using Checkly.Api.Features.Admin;
using Checkly.Api.Features.Analytics;
using Checkly.Api.Features.UserGroups;
using Checkly.Api.Features.Templates;
using Checkly.Api.Features.Programs;
using Checkly.Api.Features.Sync;
using Checkly.Api.Features.GlobalRisks;
using Checkly.Api.Features.Reference;
using Checkly.Api.Common.Scoring;
using Checkly.Api.Common.Services;
using Checkly.Api.Common.Exceptions;
using Checkly.Api.Common.Storage;
using Checkly.Api.Features.SystemInfo;
using Checkly.Api.Features.Users;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Polly;
using Polly.Retry;
using Serilog;

// Stage 1: Bootstrap logger — captures startup errors before DI.
// Guard: CreateBootstrapLogger() freezes Log.Logger. Integration tests spin up multiple
// WebApplicationFactory instances which each re-execute these top-level statements.
// The lock and static flag prevents crashing with "logger already frozen" on parallel entry.
lock (Program.LoggerLock)
{
    if (Log.Logger.GetType().Name == "SilentLogger")
    {
        Log.Logger = new LoggerConfiguration()
            .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Information)
            .Enrich.FromLogContext()
            .WriteTo.Console()
            .CreateBootstrapLogger();
    }
}

try
{
    Log.Information("Starting Checkly API");

    var builder = WebApplication.CreateBuilder(args);

    // Stage 2: Full Serilog with DI + appsettings config
    builder.Host.UseSerilog((context, services, configuration) => configuration
        .ReadFrom.Configuration(context.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .Enrich.WithEnvironmentName()
        .Enrich.WithProperty("Application", "Checkly.Api"),
        preserveStaticLogger: true,
        writeToProviders: false);

    // --- Database ---
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection") ?? "",
            npgsqlOptions =>
            {
                npgsqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 3,
                    maxRetryDelay: TimeSpan.FromSeconds(5),
                    errorCodesToAdd: null);
            }));

    // --- ASP.NET Identity ---
    builder.Services.AddIdentityCore<AppUser>(options =>
        {
            options.Password.RequireDigit = true;
            options.Password.RequireLowercase = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireNonAlphanumeric = true;
            options.Password.RequiredLength = 8;
            options.User.RequireUniqueEmail = true;
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
            options.Lockout.MaxFailedAccessAttempts = 5;
            options.Lockout.AllowedForNewUsers = true;
        })
        .AddSignInManager()
        .AddEntityFrameworkStores<AppDbContext>()
        .AddDefaultTokenProviders();

    // --- JWT Authentication ---
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = builder.Configuration["Jwt:Issuer"],
                ValidAudience = builder.Configuration["Jwt:Audience"],
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)),
                ClockSkew = TimeSpan.Zero
            };

            // F2 Fix: Token revocation on role change.
            // Runs once per authenticated request — single PK lookup on AspNetUsers (<5ms).
            // Rejects tokens issued before the user's InvalidateTokensBefore timestamp.
            options.Events = new JwtBearerEvents
            {
                OnTokenValidated = async context =>
                {
                    try
                    {
                        var userId = context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
                        if (userId is null) return;

                        var userManager = context.HttpContext.RequestServices
                            .GetRequiredService<UserManager<AppUser>>();

                        var appUser = await userManager.FindByIdAsync(userId);

                        if (appUser is null)
                        {
                            context.Fail("User not found.");
                            return;
                        }

                        if (appUser.LockoutEnd.HasValue && appUser.LockoutEnd.Value > DateTimeOffset.UtcNow)
                        {
                            context.Fail("Token revoked due to user lockout/ban.");
                            return;
                        }

                        if (appUser.InvalidateTokensBefore.HasValue)
                        {
                            // Fix: Use general SecurityToken.ValidFrom (which models nbf/iat) 
                            // to avoid InvalidCastException when .NET 8+ uses JsonWebToken.
                            var issuedAt = new DateTimeOffset(context.SecurityToken.ValidFrom, TimeSpan.Zero);

                            if (issuedAt < appUser.InvalidateTokensBefore.Value)
                            {
                                var logger = context.HttpContext.RequestServices
                                    .GetRequiredService<ILogger<Program>>();
                                logger.LogWarning(
                                    "TokenRevoked: User {UserId} presented a token issued at {IssuedAt}, " +
                                    "revoked at {RevokedAt}",
                                    userId, issuedAt, appUser.InvalidateTokensBefore.Value);

                                context.Fail("Token revoked due to role/password change.");
                                return;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        // Fail-open: a transient DB error does NOT brick all authenticated users.
                        // The security tradeoff is explicitly documented in the F2 ADR.
                        var logger = context.HttpContext.RequestServices
                            .GetRequiredService<ILogger<Program>>();
                        logger.LogWarning(ex, "TokenRevoked check failed — allowing request through.");
                    }
                }
            };
        });

    // --- Authorization Policies ---
    builder.Services.AddAuthorizationBuilder()
        .AddPolicy("AdminOnly", policy => policy.RequireRole("admin"))
        .AddPolicy("AuditorAccess", policy => policy.RequireRole("admin", "auditor"))
        .AddPolicy("StoreManagerAccess", policy => policy.RequireRole("admin", "store_manager"))
        .AddPolicy("AreaManagerAccess", policy => policy.RequireRole("admin", "area_manager"));

    // --- Application Services ---
    builder.Services.AddRequestTimeouts(options =>
    {
        options.DefaultPolicy = new Microsoft.AspNetCore.Http.Timeouts.RequestTimeoutPolicy { Timeout = TimeSpan.FromSeconds(30) };
        options.AddPolicy("LongRunning", new Microsoft.AspNetCore.Http.Timeouts.RequestTimeoutPolicy { Timeout = TimeSpan.FromMinutes(2) });
    });
    builder.Services.AddRateLimiter(options =>
    {
        options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
        options.OnRejected = async (context, token) =>
        {
            context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            context.HttpContext.Response.Headers.RetryAfter = "30";
            await context.HttpContext.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = 429,
                Title = "Too Many Requests",
                Type = "https://tools.ietf.org/html/rfc6585#section-4",
                Detail = "Server is at capacity. Please retry after 30 seconds.",
                Extensions = { ["correlationId"] = Guid.NewGuid().ToString("N")[..12] }
            }, options: null, contentType: "application/problem+json", cancellationToken: token);
        };
        options.AddFixedWindowLimiter("LoginPolicy", opt =>
        {
            opt.Window = TimeSpan.FromMinutes(1);
            opt.PermitLimit = builder.Environment.IsDevelopment() ? 1000 : 5;
            opt.QueueLimit = 0;
        });
        options.AddConcurrencyLimiter("SyncPolicy", limiterOptions =>
        {
            limiterOptions.PermitLimit = 50;
            limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
            limiterOptions.QueueLimit = 0;
        });
        options.AddConcurrencyLimiter("UploadPolicy", limiterOptions =>
        {
            // ADR: Photo Avalanche — max 6 concurrent photo file writes to prevent
            // thread-pool starvation. Queue up to 16 requests before issuing 503.
            limiterOptions.PermitLimit = 6;
            limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
            limiterOptions.QueueLimit = 16;
        });
    });
    builder.Services.AddProblemDetails();
    builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

    builder.Services.AddScoped<TokenService>();
    builder.Services.AddScoped<Register.Handler>();
    builder.Services.AddScoped<Login.Handler>();
    builder.Services.AddSingleton<ScoringVerifier>();
    builder.Services.Configure<PbacListenerOptions>(
        builder.Configuration.GetSection("Pbac"));
    builder.Services.AddSingleton<PbacDictionaryCache>();
    builder.Services.AddSingleton<IAuthorizationHandler, CapabilityAuthorizationHandler>();
    builder.Services.AddHostedService<PbacCacheListenerService>();
    builder.Services.AddSingleton<DistributedLockManager>();
    builder.Services.AddSingleton<IFileStorage, LocalFileStorage>();
    builder.Services.AddHostedService<ReminderService>();
    builder.Services.AddHostedService<OutboxBackgroundService>();

    builder.Services.AddResiliencePipeline("fcm", static pipeline =>
    {
        pipeline
            .AddRetry(new RetryStrategyOptions
            {
                MaxRetryAttempts = 3,
                BackoffType = DelayBackoffType.Exponential,
                UseJitter = true,
                Delay = TimeSpan.FromSeconds(2),
                ShouldHandle = new PredicateBuilder()
                    .Handle<Exception>(ex =>
                        ex is not FirebaseAdmin.Messaging.FirebaseMessagingException fme
                        || fme.MessagingErrorCode != FirebaseAdmin.Messaging.MessagingErrorCode.Unregistered)
            })
            .AddTimeout(TimeSpan.FromSeconds(10));
    });

    builder.Services.AddScoped<IFcmDispatchService, FcmDispatchService>();
    try
    {
        FirebaseAdmin.FirebaseApp.Create();
    }
    catch (Exception ex)
    {
        Log.Warning("FirebaseApp.Create() failed: {Message}. FCM push will be disabled.", ex.Message);
    }

    // --- SignalR ---
    builder.Services.AddSignalR();

    // --- Health Checks ---
    builder.Services.AddHealthChecks()
        .AddDbContextCheck<AppDbContext>(name: "database");

    // --- CORS ---
    builder.Services.AddCors(options =>
    {
        options.AddDefaultPolicy(policy =>
        {
            var origins = builder.Configuration
                .GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
            policy.WithOrigins(origins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        });
    });

    // --- OpenAPI (dev only) ---
    builder.Services.AddOpenApi();

    var app = builder.Build();

    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();

        // Auto-apply pending database migrations to prevent Dirty Database Traps
        // User requested to keep this fallback active while formally practicing the 3-step process.
        using var scope = app.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.Database.Migrate();

        // PBAC Cache warm-up — must run AFTER Migrate() so role_capabilities table exists.
        var pbacCache = app.Services.GetRequiredService<PbacDictionaryCache>();
        await pbacCache.InitializeAsync(app.Services);

        // Combine all PBAC capability seeding into a single batched command to reduce database round-trips
        await db.Database.ExecuteSqlRawAsync("""
            INSERT INTO role_capabilities (id, role, capability, created_at)
            VALUES
                -- Submissions Module
                (gen_random_uuid(), 'admin',         'submissions:list', now()),
                (gen_random_uuid(), 'auditor',       'submissions:list', now()),
                (gen_random_uuid(), 'store_manager', 'submissions:list', now()),
                (gen_random_uuid(), 'area_manager',  'submissions:list', now()),
                
                -- Global Risks Module
                (gen_random_uuid(), 'admin', 'global_risks:manage', now()),
                
                -- Programs Module
                (gen_random_uuid(), 'admin', 'programs:create', now()),
                (gen_random_uuid(), 'admin', 'programs:list',   now()),
                (gen_random_uuid(), 'store_manager', 'programs:assignments_my', now()),
                (gen_random_uuid(), 'store_manager', 'programs:execute', now()),
                (gen_random_uuid(), 'area_manager',  'programs:assignments_my', now()),
                (gen_random_uuid(), 'area_manager',  'programs:execute', now()),
                (gen_random_uuid(), 'admin', 'programs:assignments_list', now()),
                (gen_random_uuid(), 'area_manager', 'programs:assignments_list', now()),
                (gen_random_uuid(), 'admin', 'programs:review', now()),
                (gen_random_uuid(), 'admin', 'programs:manage', now()),
                
                -- Action Plans Module
                (gen_random_uuid(), 'store_manager', 'action_plans:write', now()),
                (gen_random_uuid(), 'admin', 'action_plans:write', now()),
                (gen_random_uuid(), 'auditor', 'action_plans:verify', now()),
                (gen_random_uuid(), 'area_manager', 'action_plans:verify', now()),
                (gen_random_uuid(), 'admin', 'action_plans:verify', now())
            ON CONFLICT (role, capability) DO NOTHING;
            """);

        // Reload cache ONCE so all seeded capabilities are immediately visible in-memory
        await pbacCache.InitializeAsync(app.Services);
    }

    // Diagnostic endpoint — only available in Development/Test environments,
    // never mapped in Production. Used by ResilienceTests to exercise GlobalExceptionHandler.
    if (!app.Environment.IsProduction())
    {
        app.MapGet("/api/test-error", () => { throw new NotImplementedException("Integration test hook."); })
           .ExcludeFromDescription();
    }

    if (!app.Environment.IsDevelopment())
    {
        app.UseHttpsRedirection();
    }

    // --- Observability Middleware (BEFORE UseCors) ---
    app.UseSerilogRequestLogging(options =>
    {
        options.MessageTemplate =
            "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms";
    });

    app.UseExceptionHandler();
    app.UseRequestTimeouts();
    app.UseRateLimiter();

    app.UseCors();
    app.UseAuthentication();
    app.UseAuthorization();

    // --- Endpoints ---
    app.MapHealthChecks("/health");
    app.MapAuthEndpoints();
    app.MapTemplateEndpoints();
    app.MapSyncEndpoints();
    app.MapStoreEndpoints();
    app.MapSubmissionEndpoints()
        .RequireRateLimiting("SyncPolicy")
        .WithRequestTimeout("LongRunning");
    app.MapPhotoEndpoints()
        .RequireRateLimiting("UploadPolicy")
        .WithRequestTimeout("LongRunning");
    app.MapActionPlanEndpoints();
    app.MapNotificationEndpoints();
    app.MapAdminEndpoints();
    app.MapGlobalRiskEndpoints();
    app.MapAnalyticsEndpoints();
    app.MapUserGroupEndpoints();
    app.MapProgramEndpoints();
    app.MapSystemEndpoints();
    app.MapUserEndpoints();
    app.MapReferenceEndpoints();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Checkly API terminated unexpectedly");
    throw;
}
finally
{
    await Log.CloseAndFlushAsync();
}

// Marker class for WebApplicationFactory<Program> in integration tests
public partial class Program
{
    public static readonly object LoggerLock = new();
}
