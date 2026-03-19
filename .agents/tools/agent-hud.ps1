param(
    [int]$RefreshInterval = 2
)

$BrainDir = "C:\Users\HP\.gemini\antigravity\brain"
$LatestSession = Get-ChildItem -Path $BrainDir -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $LatestSession) {
    Write-Host "No agent sessions found." -ForegroundColor Red
    exit
}

$TaskFile = Join-Path $LatestSession.FullName "task.md"

# Configure console
$host.UI.RawUI.WindowTitle = "🤖 Agent HUD - Live Process Tracking"

while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "   ========================================================   " -ForegroundColor Cyan
    Write-Host "   🤖 AGENT HUD : LIVE WORKFLOW TRACKING                      " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host "   Session: $($LatestSession.Name)" -ForegroundColor DarkGray
    Write-Host "   ========================================================   " -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $TaskFile) {
        $content = Get-Content $TaskFile
        foreach ($line in $content) {
            # Highlight different checklist statuses
            if ($line -match "\[x\]|\- \[x\]") {
                Write-Host "   $line" -ForegroundColor Green
            }
            elseif ($line -match "\[/\]|\- \[/\]") {
                Write-Host "   $line" -ForegroundColor Yellow
            }
            elseif ($line -match "\[ \]|\- \[ \]") {
                Write-Host "   $line" -ForegroundColor DarkGray
            } 
            # Highlight headers
            elseif ($line -match "^# ") {
                Write-Host "`n  $($line.ToUpper())" -ForegroundColor Cyan
            }
            elseif ($line -match "^## ") {
                Write-Host "`n   $line" -ForegroundColor Blue
            }
            elseif ($line -match "^### ") {
                Write-Host "`n   $line" -ForegroundColor DarkCyan
            } 
            # Blank lines
            elseif ([string]::IsNullOrWhiteSpace($line)) {
                Write-Host ""
            }
            # Normal text
            else {
                Write-Host "   $line" -ForegroundColor White
            }
        }
    }
    else {
        Write-Host "   Waiting for task.md to be created in the current session..." -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "   ========================================================   " -ForegroundColor Cyan
    Write-Host "   Press Ctrl+C to exit. Refreshing every $RefreshInterval seconds... " -ForegroundColor DarkGray
    
    Start-Sleep -Seconds $RefreshInterval
}
