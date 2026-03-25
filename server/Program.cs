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
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;

// Stage 1: Bootstrap logger — captures startup errors before DI
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Information)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateBootstrapLogger();

try
{
    Log.Information("Starting Checkly API");

    var builder = WebApplication.CreateBuilder(args);

    // Stage 2: Full Serilog with DI + appsettings config
    builder.Services.AddSerilog((services, lc) => lc
        .ReadFrom.Configuration(builder.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .Enrich.WithEnvironmentName()
        .Enrich.WithProperty("Application", "Checkly.Api"));

    // --- Database ---
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

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
    builder.Services.AddScoped<TokenService>();
    builder.Services.AddScoped<Register.Handler>();
    builder.Services.AddScoped<Login.Handler>();
    builder.Services.AddSingleton<ScoringVerifier>();
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

    app.UseExceptionHandler(errorApp =>
    {
        errorApp.Run(async context =>
        {
            var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
            var correlationId = Guid.NewGuid().ToString("N")[..12];

            Log.Error(exception,
                "Unhandled exception {CorrelationId} for {Method} {Path}",
                correlationId, context.Request.Method, context.Request.Path);

            var problem = new ProblemDetails
            {
                Title = "An unexpected error occurred",
                Status = StatusCodes.Status500InternalServerError,
                Type = "https://tools.ietf.org/html/rfc9110#section-15.6.1",
                Extensions = { ["correlationId"] = correlationId }
            };

            if (app.Environment.IsDevelopment())
                problem.Detail = exception?.Message;

            context.Response.StatusCode = 500;
            context.Response.ContentType = "application/problem+json";
            await context.Response.WriteAsJsonAsync(problem);
        });
    });

    app.UseCors();
    app.UseAuthentication();
    app.UseAuthorization();

    // --- Endpoints ---
    app.MapHealthChecks("/health");
    app.MapAuthEndpoints();
    app.MapTemplateEndpoints();
    app.MapStoreEndpoints();
    app.MapSubmissionEndpoints();
    app.MapPhotoEndpoints();
    app.MapActionPlanEndpoints();
    app.MapNotificationEndpoints();
    app.MapAdminEndpoints();
    app.MapAnalyticsEndpoints();
    app.MapAreaEndpoints();
    app.MapUserGroupEndpoints();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Checkly API terminated unexpectedly");
}
finally
{
    await Log.CloseAndFlushAsync();
}

// Marker class for WebApplicationFactory<Program> in integration tests
public partial class Program { }
