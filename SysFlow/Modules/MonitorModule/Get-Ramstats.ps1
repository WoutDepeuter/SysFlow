function Get-RamStats {
    [CmdletBinding()]
    param(
        [int]$threshold = 50
    )

    ## get ram stats and send allert when threshold is reached

    #Get RAM statistics
    $ram = Get-CimInstance -ClassName Win32_OperatingSystem

    #Calculate RAM values
    $totalGB = [math]::round($ram.TotalVisibleMemorySize / 1MB, 2)
    $freeGB  = [math]::round($ram.FreePhysicalMemory / 1MB, 2)
    $usedRam = $ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory
    $usedGB  = [math]::round($usedRam / 1MB, 2)

    #Calculate used percentage
    $usedRamPercent = [math]::round(($usedRam / $ram.TotalVisibleMemorySize) * 100, 2)

    #Display RAM statistics
    Write-Host "Total Visible Memory: $totalGB GB"
    Write-Host "Free Physical Memory: $freeGB GB"
    Write-Host "Used Physical Memory: $usedGB GB ($usedRamPercent%)"

    #Check if used RAM percentage exceeds threshold and send alert
    if ($usedRamPercent -ge $threshold) {
        Write-Host "ALERT: RAM usage is above threshold of $threshold%!" -ForegroundColor Red
    } else {
        Write-Host "RAM usage is within acceptable limits." -ForegroundColor Green
    }

    #Create and return a custom object with RAM statistics to use in other modules 
    [PSCustomObject]@{
        Total       = $totalGB
        Free        = $freeGB
        Used        = $usedGB
        UsedPercent = $usedRamPercent
    }
}


