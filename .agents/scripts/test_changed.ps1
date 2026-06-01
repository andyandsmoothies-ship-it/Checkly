# test_changed.ps1
# Script to incrementally run Flutter tests based on modified files in git diff

# 1. Gather all modified/added files from Git
$changes = @()

# Unstaged changes
$unstaged = git diff --name-only
if ($unstaged) { $changes += $unstaged }

# Staged changes
$staged = git diff --staged --name-only
if ($staged) { $changes += $staged }

# Untracked files
$untracked = git status --porcelain | Where-Object { $_ -match '^\?\?\s+(.+)' } | ForEach-Object { $Matches[1] }
if ($untracked) { $changes += $untracked }

# Deduplicate change list
$changes = $changes | Select-Object -Unique

if ($changes.Count -eq 0) {
    Write-Host "No modified files detected in the workspace." -ForegroundColor Green
    exit 0
}

Write-Host "Detected changes in the following files:" -ForegroundColor Cyan
foreach ($file in $changes) {
    Write-Host " - $file"
}

# 2. Map source files to test files
$testsToRun = @()

foreach ($file in $changes) {
    # Normalize paths to use forward slashes
    $normalizedFile = $file.Replace("\", "/")

    # Check if the file is already a test file
    if ($normalizedFile -match '^test/.*_test\.dart$') {
        if (Test-Path $normalizedFile) {
            $testsToRun += $normalizedFile
        }
    }
    # Check if the file is a source Dart file
    elseif ($normalizedFile -match '^lib/(.*)\.dart$') {
        $relativePath = $Matches[1]
        $potentialTest = "test/$relativePath" + "_test.dart"

        if (Test-Path $potentialTest) {
            $testsToRun += $potentialTest
        } else {
            Write-Host "No direct test file found matching: $potentialTest" -ForegroundColor Yellow
        }
    }
}

# Deduplicate tests
$testsToRun = $testsToRun | Select-Object -Unique

# 3. Execute tests
if ($testsToRun.Count -eq 0) {
    Write-Host "No corresponding tests found for the changed files." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nRunning the following incremental tests:" -ForegroundColor Green
foreach ($test in $testsToRun) {
    Write-Host " - $test" -ForegroundColor Green
}

$testArgs = $testsToRun -join " "
$cmd = "flutter test $testArgs"

Write-Host "`nExecuting: $cmd" -ForegroundColor Gray
Invoke-Expression $cmd

exit $LASTEXITCODE
