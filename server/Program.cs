using System.Text;
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
using Checkly.Api.Features.Areas;
using Checkly.Api.Features.UserGroups;
using Checkly.Api.Features.Templates;
using Checkly.Api.Common.Scoring;
using Checkly.Api.Common.Services;
using Checkly.Api.Common.Exceptions;
using Checkly.Api.Features.SystemInfo;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;

// Stage 1: Bootstrap logger — captures startup errors before DI.
// Guard: CreateBootstrapLogger() freezes Log.Logger. Integration tests spin up multiple
// WebApplicationFactory instances which each re-execute these top-level statements.
// The static flag prevents crashing with "logger already frozen" on repeated entry.
if (Log.Logger.GetType().Name == "SilentLogger")
{
    Log.Logger = new LoggerConfiguration()
        .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Information)
        .Enrich.FromLogContext()
        .WriteTo.Console()
        .CreateBootstrapLogger();
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
        .Enrich.WithProperty("Application", "Checkly.Api"));

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
        });

    // --- Authorization Policies ---
    builder.Services.AddAuthorizationBuilder()
        .AddPolicy("AdminOnly", policy => policy.RequireRole("admin"))
        .AddPolicy("AuditorAccess", policy => policy.RequireRole("admin", "auditor"))
        .AddPolicy("StoreManagerAccess", policy => policy.RequireRole("admin", "store_manager"))
        .AddPolicy("AreaManagerAccess", policy => policy.RequireRole("admin", "area_manager"));

    // --- Application Services ---
    builder.Services.AddRequestTimeouts(options => {
        options.DefaultPolicy = new Microsoft.AspNetCore.Http.Timeouts.RequestTimeoutPolicy { Timeout = TimeSpan.FromSeconds(30) };
        options.AddPolicy("LongRunning", new Microsoft.AspNetCore.Http.Timeouts.RequestTimeoutPolicy { Timeout = TimeSpan.FromMinutes(2) });
    });
    builder.Services.AddRateLimiter(options =>
    {
        options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
        options.OnRejected = async (context, token) =>
        {
            context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            await context.HttpContext.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = 429,
                Title = "Too Many Requests",
                Type = "https://tools.ietf.org/html/rfc6585#section-4",
                Detail = "Server is at capacity. Please retry after a moment.",
                Extensions = { ["correlationId"] = Guid.NewGuid().ToString("N")[..12] }
            }, options: null, contentType: "application/problem+json", cancellationToken: token);
        };
        options.AddConcurrencyLimiter("SyncPolicy", limiterOptions =>
        {
            limiterOptions.PermitLimit = 50;
            limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
            limiterOptions.QueueLimit = 0;
        });
        options.AddConcurrencyLimiter("UploadPolicy", limiterOptions =>
        {
            limiterOptions.PermitLimit = 20;
            limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
            limiterOptions.QueueLimit = 0;
        });
    });
    builder.Services.AddProblemDetails();
    builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

    builder.Services.AddScoped<TokenService>();
    builder.Services.AddScoped<Register.Handler>();
    builder.Services.AddScoped<Login.Handler>();
    builder.Services.AddSingleton<ScoringVerifier>();
    builder.Services.AddSingleton<PbacDictionaryCache>();
    builder.Services.AddSingleton<IAuthorizationHandler, CapabilityAuthorizationHandler>();
    builder.Services.AddHostedService<ReminderService>();

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
    app.MapAnalyticsEndpoints();
    app.MapAreaEndpoints();
    app.MapUserGroupEndpoints();
    app.MapSystemEndpoints();

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
public partial class Program { }
