# Test Execution Log

## Scope
Tested the `FinalizeSubmission` functionality after removing the `.RequireCapability(AppCapabilities.SubmissionsCreate)` mapping.

## Trace
<test_trace>
C:\Users\HP\Documents\GitHub\Checkly\server> dotnet test tests/Checkly.Api.Tests/ --filter FullyQualifiedName~FinalizeSubmission
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:    16, Skipped:     0, Total:    16, Duration: 9 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
C:\Users\HP\Documents\GitHub\Checkly\server> dotnet test tests/Checkly.Api.Tests/
Passed: 652
Failed: 1 (GetCapabilityCatalog_Returns17Capabilities_IncludingProgramExecution) - Known track B expansion issue, outside blast radius.
</forensic_evidence>
