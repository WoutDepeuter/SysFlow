function Get-RamStats {
    <#
    .SYNOPSIS
        Retrieves RAM statistics and checks against a specified threshold.

    .DESCRIPTION
        The Get-RamStats function gathers memory usage statistics using CIM.
        It calculates total, free, and used memory in GB, along with the percentage of memory in use.
        If memory usage exceeds the specified threshold, an alert is displayed.

    .PARAMETER threshold
        The RAM usage percentage threshold for triggering an alert.
        Default value is 50. If RAM usage exceeds this percentage, a warning is displayed.

    .EXAMPLE
        Get-RamStats
        
        Retrieves RAM statistics with the default threshold of 50%.

    .EXAMPLE
        Get-RamStats -threshold 80
        
        Retrieves RAM statistics and alerts if RAM usage exceeds 80%.

    .EXAMPLE
        $ramInfo = Get-RamStats -threshold 70 -Verbose
        Write-Host "Total RAM: $($ramInfo.Total) GB"
        Write-Host "Used: $($ramInfo.UsedPercent)%"
        
        Retrieves RAM stats with verbose output and displays specific properties.

    .OUTPUTS
        PSCustomObject with properties:
        - Total: Total visible memory in GB
        - Free: Free physical memory in GB
        - Used: Used physical memory in GB
        - UsedPercent: Percentage of memory in use

    .NOTES
        Author: SysFlow
        Version: 1.0
        Requires: PowerShell with CIM access
    #>
    #get help writen with help from copilot

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


