$targetDirs = @("docs/architecture", "docs/product", "docs/qa/contracts", "docs/qa/gates")

foreach ($dir in $targetDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -File -Filter "*.md"
        foreach ($file in $files) {
            # Regex to match the standard format: _YYYYMMDD_HHMMSS_ShortID_Topic.md
            if ($file.Name -match '_(\d{8})_(\d{4,6})_([a-zA-Z0-9]+)_(.+)\.md$') {
                $topic = $matches[4]
                
                $topicDir = Join-Path -Path $dir -ChildPath $topic
                if (-not (Test-Path $topicDir)) {
                    New-Item -ItemType Directory -Path $topicDir | Out-Null
                    Write-Host "Created directory: $topicDir"
                }
                
                $destination = Join-Path -Path $topicDir -ChildPath $file.Name
                Move-Item -Path $file.FullName -Destination $destination
                Write-Host "Moved $($file.Name) to $topicDir"
            } else {
                Write-Host "Skipping non-compliant file: $($file.Name)"
            }
        }
    }
}
Write-Host "Done organizing docs."
