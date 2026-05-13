# Executed Tests

Test run for Checkly.Api.Tests.dll
Total: 494
Passed: 491
Failed: 0
Skipped: 3

Tests ran successfully.

<test_trace>
  Determining projects to restore...
  All projects are up-to-date for restore.
  Checkly.Api -> C:\Users\HP\Documents\GitHub\Checkly\server\bin\Debug\net10.0\Checkly.Api.dll
  Checkly.Api.Tests -> C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.
[xUnit.net 00:00:30.68]     Checkly.Api.Tests.FilteredTemplateSyncTests.SyncTemplates_UnassignedTemplate_VisibleToAllAuditors [SKIP]
[xUnit.net 00:00:30.68]     Checkly.Api.Tests.FilteredTemplateSyncTests.SyncTemplates_Admin_SeesAllTemplatesRegardless [SKIP]
[xUnit.net 00:00:30.68]     Checkly.Api.Tests.FilteredTemplateSyncTests.SyncTemplates_AssignedTemplate_VisibleOnlyToGroupMembers [SKIP]
  Skipped Checkly.Api.Tests.FilteredTemplateSyncTests.SyncTemplates_UnassignedTemplate_VisibleToAllAuditors [1 ms]
  Skipped Checkly.Api.Tests.FilteredTemplateSyncTests.SyncTemplates_Admin_SeesAllTemplatesRegardless [1 ms]
  Skipped Checkly.Api.Tests.FilteredTemplateSyncTests.SyncTemplates_AssignedTemplate_VisibleOnlyToGroupMembers [1 ms]

Passed!  - Failed:     0, Passed:   491, Skipped:     3, Total:   494, Duration: 2 m 13 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
cmd /c "cd server && dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj > ..\.agents\tmp\test_results.txt 2>&1"
</forensic_evidence>
