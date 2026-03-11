namespace Checkly.Api.Features.Auth;

/// <summary>
/// Maps the /api/auth route group (anonymous access).
/// </summary>
public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/auth")
            .WithTags("Auth")
            .AllowAnonymous();

        group.MapPost("/register", async (
            Register.Request request,
            Register.Handler handler,
            HttpContext httpContext,
            CancellationToken ct) =>
        {
            return await handler.ExecuteAsync(request, httpContext, ct);
        })
        .WithName("Register");

        group.MapPost("/login", async (
            Login.Request request,
            Login.Handler handler,
            CancellationToken ct) =>
        {
            return await handler.ExecuteAsync(request, ct);
        })
        .WithName("Login");
    }
}
