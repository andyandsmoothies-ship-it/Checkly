using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Serilog;

namespace Checkly.Api.Common.Exceptions;

public class GlobalExceptionHandler(IWebHostEnvironment env) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var correlationId = Guid.NewGuid().ToString("N")[..12];

        Log.Error(exception,
            "Unhandled exception {CorrelationId} for {Method} {Path}",
            correlationId, httpContext.Request.Method, httpContext.Request.Path);

        var problemDetails = new ProblemDetails
        {
            Title = "An unexpected error occurred",
            Status = StatusCodes.Status500InternalServerError,
            Type = "https://tools.ietf.org/html/rfc9110#section-15.6.1",
            Extensions = { ["correlationId"] = correlationId }
        };

        if (env.IsDevelopment())
        {
            problemDetails.Detail = exception.Message;
        }

        httpContext.Response.StatusCode = StatusCodes.Status500InternalServerError;

        await httpContext.Response.WriteAsJsonAsync(
            problemDetails, 
            options: null, 
            contentType: "application/problem+json", 
            cancellationToken: cancellationToken);
        
        return true;
    }
}
