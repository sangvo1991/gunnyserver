# Define the log file path
$nginxPath = "C:\gunny\nginx\logs"
$winrarPath = "C:\Program Files\WinRAR\Rar.exe"
$archiveLogs = "$nginxPath\logs.rar"
Set-Location $nginxPath
# Define the maximum number of log files to retain (adjust as needed)
# Get the current date in a timestamp-friendly format (YYYYMMDD_HHMMSS)
$timestamp = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")

if (Test-Path "$nginxPath\access.log" -PathType Leaf){
    Copy-Item "$nginxPath\access.log" "$nginxPath\access_$timestamp.log"
    do {
        Set-Location "$nginxPath\.."
        Start-Process -FilePath "nginx.exe" -ArgumentList "-s", "quit" -ErrorAction SilentlyContinue
        try {
            # Start-Sleep -Milliseconds 100
            Start-Sleep -Seconds 1
            "" | Out-File -FilePath "$nginxPath\access.log" -Encoding ASCII
            $success = $true
        }
        catch {
            Write-Host "An error occurred: $_"  # $_ contains the error message
            Write-Host "Failed to write to $nginxPath\access.log. Retrying"
        }
    } while (-not $success)
    Start-Process -FilePath "nginx.exe"
    # Arhive log
    # & "./nginx.exe" 
    Set-Location $nginxPath
    & $winrarPath a -ep1 -r $archiveLogs "$nginxPath\access_$timestamp.log"
    Remove-Item "$nginxPath\access_$timestamp.log"
}

# Remove all logs file older than 15 days
$maxAgeDays = 15
if (Test-Path "$archiveLogs" -PathType Leaf){
    & $winrarPath x -y -o+ "$archiveLogs" "$nginxPath\tmp_extract\"
    $minDate = (Get-Date).AddDays(-$maxAgeDays)
    foreach ($file in (Get-ChildItem -Path "$nginxPath\tmp_extract\")){
        if ($file.LastWriteTime -lt $minDate){
            Remove-Item -Path $file.FullName -Force
        }
    }
    & $winrarPath u -r -ep1 -df -u $archiveLogs "$nginxPath\tmp_extract\*.log"
    Remove-Item -Path "$nginxPath\tmp_extract\" -Force -Recurse
}
