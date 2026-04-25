$ErrorActionPreference = "Stop"

$testFiles = @(
    "server/tests/Checkly.Api.Tests/bin/Debug/test.dll",
    "server/tests/Checkly.Api.Tests/obj/Debug/test.o",
    "server/tests/Checkly.Api.Tests/TestResults/result.trx",
    "server/data/photos/test.jpg",
    "server/.agents/tmp/debug.txt",
    "test_results.json"
)

$failedCount = 0

foreach ($file in $testFiles) {
    # We check what gitcheck-ignore says. 
    # git check-ignore returns 0 if ignored, 1 if not ignored.
    $process = Start-Process -FilePath "git" -ArgumentList "check-ignore", "-q", "$file" -PassThru -Wait -NoNewWindow
    if ($process.ExitCode -ne 0) {
        Write-Host "RED: $file is NOT ignored by git." -ForegroundColor Red
        $failedCount++
    } else {
        Write-Host "GREEN: $file is properly ignored." -ForegroundColor Green
    }
}

if ($failedCount -gt 0) {
    Write-Host "ATDD Test Failed: $failedCount artifacts are not ignored." -ForegroundColor Red
    exit 1
} else {
    Write-Host "ATDD Test Passed: All artifacts are ignored." -ForegroundColor Green
    exit 0
}
