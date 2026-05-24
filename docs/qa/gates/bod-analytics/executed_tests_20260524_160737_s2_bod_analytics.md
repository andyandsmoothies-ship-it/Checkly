# Executed Tests: BOD Analytics Slice 2 (API Gateway) — RED Phase

Date: 2026-05-24
Test Suite: `Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests`
Phase: **RED Phase (Specification & Contracts Verified)**

## Execution Command
```cmd
rtk dotnet test tests/Checkly.Api.Tests --filter "FullyQualifiedName~Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests"
```

## Raw Output Log
<test_trace>
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.RefreshBodReport_AsAdmin_TriggersRefresh [58 ms]
Error Message:
 First manual refresh trigger failed (NotFound): 
Stack Trace:
   at Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.RefreshBodReport_AsAdmin_TriggersRefresh() in C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Analytics\BodAnalyticsEndpointTests.cs:line 236

Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.RefreshBodReport_RateLimitsConsecutiveRequests [56 ms]
Error Message:
 System.InvalidOperationException : No service for type 'Checkly.Api.Features.Analytics.BodReportWorker' has been registered.
Stack Trace:
   at Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions.GetRequiredService(IServiceProvider provider, Type serviceType)
   at Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions.GetRequiredService[T](IServiceProvider provider)
   at Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.RefreshBodReport_RateLimitsConsecutiveRequests() in C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Analytics\BodAnalyticsEndpointTests.cs:line 256

Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.GetBodReport_AsAuditor_ReturnsForbidden [63 ms]
Error Message:
 Expected Forbidden (403), but got NotFound. Body: 
Stack Trace:
   at Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.GetBodReport_AsAuditor_ReturnsForbidden() in C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Analytics\BodAnalyticsEndpointTests.cs:line 146

Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.RefreshBodReport_ConcurrentTriggers_RespectsLock
Error Message:
System.InvalidOperationException : No service for type 'Checkly.Api.Features.Analytics.BodReportWorker' has been registered.

Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.GetBodReport_AsAdmin_ReturnsSuccessAndPayload
Error Message:
Status: NotFound. Body:

Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.GetBodReport_EmptyDatabase_ReturnsNotFound
Error Message:
System.Text.Json.JsonException : The input does not contain any JSON tokens.

Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests.RefreshBodReport_AsAuditor_ReturnsForbidden
Error Message:
Expected Forbidden (403), but got NotFound.

Failed!  - Failed:     7, Passed:     0, Skipped:     0, Total:     7, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

## Forensic Evidence
<forensic_evidence>
Executed target integration tests using dotnet test runner with rtk wrapper.
All 7 integration test cases failed with expected 404 (NotFound) and InvalidOperationException (No service registered) errors.
This confirms the RED phase is verified: the tests compiles successfully, and they assert the correct business behaviors that will pass once the production slice is wired up.
</forensic_evidence>

## Details of Executed Scenarios
1. **`GetBodReport_AsAdmin_ReturnsSuccessAndPayload`**: FAILS with `404 Not Found` (endpoint does not exist yet).
2. **`GetBodReport_AsAuditor_ReturnsForbidden`**: FAILS with `404 Not Found` instead of `403 Forbidden` (endpoint does not exist yet).
3. **`RefreshBodReport_AsAuditor_ReturnsForbidden`**: FAILS with `404 Not Found` instead of `403 Forbidden` (endpoint does not exist yet).
4. **`GetBodReport_EmptyDatabase_ReturnsNotFound`**: FAILS with `JsonReaderException` due to empty 404 body (endpoint does not exist yet).
5. **`RefreshBodReport_AsAdmin_TriggersRefresh`**: FAILS with `404 Not Found` (endpoint does not exist yet).
6. **`RefreshBodReport_RateLimitsConsecutiveRequests`**: FAILS with `InvalidOperationException` (BodReportWorker DI registration missing).
7. **`RefreshBodReport_ConcurrentTriggers_RespectsLock`**: FAILS with `InvalidOperationException` (BodReportWorker DI registration missing).
