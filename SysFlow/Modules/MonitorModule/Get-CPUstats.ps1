function Get-CPUStats {
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
