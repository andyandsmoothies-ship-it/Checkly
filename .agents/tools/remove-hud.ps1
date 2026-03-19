
# Removes all HUD blocks from workflow files.
# Looks for <!-- HUD:START --> to <!-- HUD:END --> markers and deletes them.
# Run this once to turn off the Live Dashboard from all workflows.

param(
    [string]$WorkflowDir = "c:\Users\HP\Documents\GitHub\Checkly\.agents\workflows"
)

$modified = @()

Get-ChildItem -Path $WorkflowDir -Filter "*.md" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw
    
    if ($content -match "HUD:START") {
        $content = $content -replace '(?s)\r?\n?\<!-- HUD:START.*?HUD:END -->\r?\n?', "`n"
        Set-Content -Path $file -Value $content -NoNewline
        $modified += $_.BaseName
    }
}

if ($modified.Count -gt 0) {
    Write-Host "Removed HUD from $($modified.Count) workflows:" -ForegroundColor Green
    $modified | ForEach-Object { Write-Host "  $_" }
}
else {
    Write-Host "No HUD blocks found in any workflow." -ForegroundColor Yellow
}
