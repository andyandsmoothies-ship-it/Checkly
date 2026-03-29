$files = Get-ChildItem -Path lib -Recurse -Filter *.dart
$results = @()
foreach ($f in $files) {
    $lines = (Get-Content $f.FullName | Measure-Object -Line).Lines
    $rel = $f.FullName.Replace((Get-Location).Path + "\", "")
    $results += [PSCustomObject]@{ File = $rel; Lines = $lines }
}
$results | Sort-Object Lines -Descending | Select-Object -First 20 | Format-Table -AutoSize
