function Get-CPUStats {
    
    <#
    .SYNOPSIS
        Retrieves CPU statistics and checks against a specified threshold.

    .DESCRIPTION
        The Get-CPUStats function gathers CPU load percentage and other relevant statistics using CIM.
        It checks if the CPU load exceeds a defined threshold and provides an alert if necessary.
        Returns a custom object with CPU name, load percentage, number of cores, and logical processors.

    .PARAMETER threshold
        The CPU load percentage threshold for triggering an alert.
        Default value is 50. If CPU load exceeds this percentage, a warning is displayed.

    .EXAMPLE
        Get-CPUStats
        
        Retrieves CPU statistics with the default threshold of 50%.

    .EXAMPLE
        Get-CPUStats -threshold 75
        
        Retrieves CPU statistics and alerts if CPU load exceeds 75%.

    .EXAMPLE
        $cpuInfo = Get-CPUStats -threshold 80 -Verbose
        Write-Host "CPU: $($cpuInfo.Name)"
        Write-Host "Load: $($cpuInfo.LoadPercentage)%"
        
        Retrieves CPU stats with verbose output and displays specific properties.

    .OUTPUTS
        PSCustomObject with properties:
        - Name: CPU processor name
        - LoadPercentage: Current CPU load as a percentage
        - NumberOfCores: Physical CPU cores
        - NumberOfLogicalProcessors: Logical processors (includes hyperthreading)

    .NOTES
        Author: SysFlow
        Version: 1.0
        Requires: PowerShell with CIM access
    #>


    [CmdletBinding()]
    param(
        [int]$threshold = 50
    )

    #CPU stats
    $cpu = Get-CimInstance -ClassName Win32_Processor

    #Display CPU load percentage
    Write-Host "Current CPU Load Percentage: $($cpu.LoadPercentage)%"

    #Check if CPU load percentage exceeds threshold and send alert
    if ($cpu.LoadPercentage -ge $threshold) {
        Write-Host "ALERT: CPU load is above threshold of $threshold%!" -ForegroundColor Red
    } else {
        Write-Host "CPU load is within acceptable limits." -ForegroundColor Green
    }

    #Create and return a custom object with CPU statistics to use in other modules
    [PSCustomObject]@{
        Name                       = $cpu.Name
        LoadPercentage             = $cpu.LoadPercentage
        NumberOfCores              = $cpu.NumberOfCores
        NumberOfLogicalProcessors  = $cpu.NumberOfLogicalProcessors
    }
}
