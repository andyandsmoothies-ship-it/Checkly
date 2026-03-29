$files = Get-ChildItem -Path lib -Recurse -Filter *.dart | Where-Object { $_.Name -notmatch '\.g\.dart|\.freezed\.dart' }
foreach ($f in $files) {
    # Count how many lines contain 'class '
    $c = (Get-Content $f.FullName | Select-String -Pattern '^\s*class ' -CaseSensitive).Count
    if ($c -gt 3) {
        $rel = $f.FullName.Replace((Get-Location).Path + "\", "")
        Write-Host "$rel has $c classes"
    }
}
