function Get-Uptime {
    # Get OS details
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    
    # Calculate the timespan
    $uptime = (Get-Date) - $os.LastBootUpTime
    
    # Create and return the custom object immediately
    [PSCustomObject]@{
        Days    = $uptime.Days
        Hours   = $uptime.Hours
        Minutes = $uptime.Minutes
        Seconds = $uptime.Seconds
        # Optional: readable total hours for quick math
        TotalHours = [math]::Round($uptime.TotalHours, 2) 
    }
}
