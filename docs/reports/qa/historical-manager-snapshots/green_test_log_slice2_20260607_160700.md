# Green Test Log: Historical Manager Snapshots - Slice 2

This log confirms that all integration and contract tests for the API DTO properties of the Submission Manager Snapshots are passing.

## Test Environment

- **Suite**: `Checkly.Api.Tests`
- **Command**: `rtk proxy dotnet test server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter SubmissionManagerSnapshotDto`
- **Date**: 2026-06-07

## Test Output

```
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:     3, Skipped:     0, Total:     3, Duration: 5 s - Checkly.Api.Tests.dll (net10.0)
```

## Verified Tests

1. `GetSubmission_ShouldReturn_ManagerSnapshots_WhenPopulated`
2. `ListSubmissions_ShouldReturn_ManagerSnapshots_WhenPopulated`
3. `UpdateSubmission_ShouldReturn_ManagerSnapshots_WhenPopulated`
4. `FinalizeSubmission_ShouldReturn_ManagerSnapshots_WhenPopulated`
