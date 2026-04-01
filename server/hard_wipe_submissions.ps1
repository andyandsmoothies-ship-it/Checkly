# Hard Wipe Checkly Submissions
# WARNING: This script deletes ALL historical audit data from the local dev database.

$env:PGPASSWORD = "Aa1234567@"
$psqlPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
$dbName = "checkly"
$dbUser = "postgres"

Write-Host "--- DETECTED REQUEST: Hard Wipe Test Submissions ---" -ForegroundColor Yellow
Write-Host "This will permanently delete data from: action_plans, answers, submission_section_scores, and submissions." -ForegroundColor Cyan

# SQL to truncate tables with Cascade to handle FKs
$sql = "TRUNCATE TABLE action_plans, answers, submission_section_scores, submissions CASCADE;"

& $psqlPath -h localhost -p 5432 -U $dbUser -d $dbName -c "$sql"

if ($LASTEXITCODE -eq 0) {
    Write-Host "--- SUCCESS: All submissions and children have been wiped. ---" -ForegroundColor Green
    Write-Host "Note: You may need to 'Clear App Data' on your mobile device to clear the local Drift cache." -ForegroundColor Gray
} else {
    Write-Host "--- ERROR: Failed to wipe database. Check if PostgreSQL is running. ---" -ForegroundColor Red
}

$env:PGPASSWORD = $null
