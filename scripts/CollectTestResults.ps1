param (
    [string]$Project = "server/tests/Checkly.Api.Tests",
    [string]$ExportFormat = "csv" # 'csv' or 'json'
)

$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$TrxFolder = "TestResults"
$TrxFile = "raw_results_$timestamp.trx"
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) { $ScriptDir = (Get-Location).Path }

$TrxFullPath = Join-Path $ScriptDir "$TrxFolder\$TrxFile"

Write-Host "Running dotnet test on $Project..." -ForegroundColor Cyan
Write-Host "Generating raw TRX output at: $TrxFullPath" -ForegroundColor DarkGray

# Run dotnet test and generate TRX logger output
# We suppress the console output to keep the terminal clean, since we only care about the analytics
dotnet test $Project --logger "trx;LogFileName=$TrxFullPath" --verbosity quiet

if (Test-Path $TrxFullPath) {
    Write-Host "Tests completed. Parsing results..." -ForegroundColor Cyan
    
    [xml]$trxInfo = Get-Content $TrxFullPath
    
    # The TRX file uses an XML namespace
    $ns = @{ t = "http://microsoft.com/schemas/VisualStudio/TeamTest/2010" }

    $testResults = @()
    
    $nodes = Select-Xml -Xml $trxInfo -XPath "//t:UnitTestResult" -Namespace $ns
    foreach ($node in $nodes) {
        $r = $node.Node
        $testResults += [PSCustomObject]@{
            TestName = $r.testName
            Outcome  = $r.outcome
            Duration = $r.duration
            Error    = if ($r.outcome -eq 'Failed') { $r.Output.ErrorInfo.Message.Trim() } else { $null }
        }
    }

    if ($ExportFormat -eq "json") {
        $ExportPath = Join-Path $ScriptDir "test_analytics_$timestamp.json"
        $testResults | ConvertTo-Json -Depth 3 | Out-File $ExportPath
        Write-Host "Successfully exported $($testResults.Count) tests to: $ExportPath" -ForegroundColor Green
    } else {
        $ExportPath = Join-Path $ScriptDir "test_analytics_$timestamp.csv"
        $testResults | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "Successfully exported $($testResults.Count) tests to: $ExportPath" -ForegroundColor Green
    }

} else {
    Write-Host "Failed to locate the generated TRX file! Ensure dotnet test completed successfully." -ForegroundColor Red
}
