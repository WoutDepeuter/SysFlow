function Get-Uptime {
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
