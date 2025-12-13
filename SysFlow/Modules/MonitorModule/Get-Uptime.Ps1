function Get-Uptime {

    <#
    .SYNOPSIS
        Retrieves the system uptime.
    .DESCRIPTION
        The Get-Uptime function calculates the duration for which the system has been running since the last boot.
        It retrieves the last boot time using CIM and computes the uptime as a timespan.
        Returns a custom object with detailed uptime information including days, hours, minutes, seconds, and total hours.
    .EXAMPLE
        Get-Uptime
        
        Retrieves the system uptime and displays it.
    .EXAMPLE
        $uptimeInfo = Get-Uptime
        Write-Host "System Uptime: $($uptimeInfo.Days) days, $($uptimeInfo.Hours) hours, $($uptimeInfo.Minutes) minutes"
        
        Retrieves the uptime and formats the output to show days, hours, and minutes.
    .OUTPUTS
        PSCustomObject with properties:
        - Uptime: TimeSpan object representing the total uptime
        - Days: Number of days the system has been up
        - Hours: Number of hours (excluding days)
        - Minutes: Number of minutes (excluding hours)
        - Seconds: Number of seconds (excluding minutes)
        - TotalHours: Total uptime in hours (rounded to 2 decimal places)   
    .NOTES

 #>
    # Get OS details
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    
    # Calculate the timespan
    $uptime = (Get-Date) - $os.LastBootUpTime
    
    # Create and return the custom object with Uptime property
    [PSCustomObject]@{
        Uptime     = $uptime
        Days       = $uptime.Days
        Hours      = $uptime.Hours
        Minutes    = $uptime.Minutes
        Seconds    = $uptime.Seconds
        TotalHours = [math]::Round($uptime.TotalHours, 2) 
    }
}
