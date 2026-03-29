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
        // Branch 1: Request timeout abort → 504 Gateway Timeout
        // The request token is already cancelled here, so CancellationToken.None is mandatory.
        if (exception is OperationCanceledException &&
            !httpContext.RequestAborted.IsCancellationRequested)
        {
            var timeoutCorrelationId = Guid.NewGuid().ToString("N")[..12];

            Log.Warning("Request timeout {CorrelationId} for {Method} {Path}",
                timeoutCorrelationId, httpContext.Request.Method, httpContext.Request.Path);

            httpContext.Response.StatusCode = StatusCodes.Status504GatewayTimeout;

            await httpContext.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = StatusCodes.Status504GatewayTimeout,
                Title = "Request Timeout",
                Type = "https://tools.ietf.org/html/rfc9110#section-15.6.5",
                Detail = "The request exceeded the allowed time limit.",
                Extensions = { ["correlationId"] = timeoutCorrelationId }
            }, options: null, contentType: "application/problem+json",
               cancellationToken: CancellationToken.None);

            return true;
        }

        // Branch 2: All other unhandled exceptions → 500 Internal Server Error
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
