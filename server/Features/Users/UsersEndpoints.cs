using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;

namespace Checkly.Api.Features.Users;

public static class UsersEndpoints
{
    public static IEndpointRouteBuilder MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        RegisterDeviceToken.MapEndpoint(app);
        SearchUsers.MapEndpoint(app);
        return app;
    }
}
