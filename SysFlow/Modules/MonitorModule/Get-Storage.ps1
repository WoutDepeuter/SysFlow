param(

    [ValidateRange(1,99)]
    [int]$Threshold = 80
)

# Use Write-Host for status messages so they don't get mixed into your data export
Write-Host "Checking storage usage..." -ForegroundColor Cyan

# Get all local fixed drives (DriveType=3)
$drives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"

# Initialize an array to hold results
$results = foreach ($drive in $drives) {

    # Calculate used space and percentage
    if ($drive.Size -gt 0) {
        $usedSpace = $drive.Size - $drive.FreeSpace
        $usedPercentage = [math]::Round(($usedSpace / $drive.Size) * 100, 2)
        

        # Determine status
        if ($usedPercentage -ge $Threshold) {
            $status = "CRITICAL"
            # Write-Warning prints to console but doesn't corrupt the data stream
            Write-Warning "Alert: Drive $($drive.DeviceID) is at $usedPercentage%"
        } else {
            $status = "OK"
        }
        #sets status 

        # Create a Custom Object. This makes the data reusable.
        [PSCustomObject]@{
            DriveLetter   = $drive.DeviceID
            Label         = $drive.VolumeName
            TotalSizeGB   = [math]::Round($drive.Size / 1GB, 2)
            FreeSpaceGB   = [math]::Round($drive.FreeSpace / 1GB, 2)
            UsedPercent   = $usedPercentage
            Status        = $status
        }
    }
}


return $results