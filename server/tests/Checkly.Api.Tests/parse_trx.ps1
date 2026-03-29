$trxPath = "TestResults\results.trx"
[xml]$trx = Get-Content $trxPath
$failed = $trx.TestRun.Results.UnitTestResult | Where-Object { $_.outcome -eq "Failed" }
foreach ($t in $failed) {
    Write-Host "=== FAILED: $($t.testName) ==="
    Write-Host "MESSAGE: $($t.Output.ErrorInfo.Message)"
    Write-Host "STACKTRACE:"
    Write-Host $t.Output.ErrorInfo.StackTrace
    Write-Host "---"
}
Write-Host "Total failed: $($failed.Count)"
