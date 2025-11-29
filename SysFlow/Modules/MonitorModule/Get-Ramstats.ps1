## get ram stats and send allert when threshold is reached
param(
    [int]$treshold = 50

)
#Get RAM statistics
$ram = Get-CimInstance -ClassName Win32_OperatingSystem
#Display RAM statistics and convert to GB
write-Host "Total Visible Memory: $([math]::round($ram.TotalVisibleMemorySize/1MB,2)) GB"
write-Host "Free Physical Memory: $([math]::round($ram.FreePhysicalMemory/1MB,2)) GB"
#Calculate used RAM and percentage
$usedRam = $ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory
$usedRamPercent = [math]::round(($usedRam / $ram.TotalVisibleMemorySize) * 100,2)
write-Host "Used Physical Memory: $([math]::round($usedRam/1MB,2)) GB ($usedRamPercent`%)"
#Check if used RAM percentage exceeds threshold and send alert

if ($usedRamPercent -ge $treshold) {
    Write-Host "ALERT: RAM usage is above threshold of $treshold`%!" -ForegroundColor Red
} else {
    Write-Host "RAM usage is within acceptable limits." -ForegroundColor Green
}

#End of script
