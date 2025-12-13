function Get-StorageStats {
    <#
    .SYNOPSIS
        Retrieves storage statistics for local drives and alerts if usage exceeds a specified threshold.    
    .DESCRIPTION
        The Get-StorageStats function gathers storage information for all local fixed drives using CIM.
        It calculates total size, free space, and used percentage for each drive.
        If the used percentage exceeds the defined threshold, a warning alert is displayed.
        Returns a custom object with drive letter, label, total size, free space, used percentage, and status.
    .PARAMETER Threshold
        The storage usage percentage threshold for triggering an alert.
        Default value is 80. If storage usage exceeds this percentage, a warning is displayed. 
    .EXAMPLE
        Get-StorageStats
        
        Retrieves storage statistics with the default threshold of 80%.
    .EXAMPLE
        Get-StorageStats -Threshold 90
        
        Retrieves storage statistics and alerts if storage usage exceeds 90%.
    .EXAMPLE
        $storageInfo = Get-StorageStats -Threshold 75 -Verbose
        Write-Host "Drive C: Used: $($storageInfo | Where-Object { $_.DriveLetter -eq 'C:' } | Select-Object -ExpandProperty UsedPercent)%"
        
        Retrieves storage stats with verbose output and displays specific properties.
    .OUTPUTS    
        PSCustomObject with properties:
        - DriveLetter: Drive letter (e.g., C:)
        - Label: Volume label
        - TotalSizeGB: Total size of the drive in GB
        - FreeSpaceGB: Free space available in GB
        - UsedPercent: Percentage of used space
        - Status: OK or CRITICAL based on threshold
    .NOTES
#>

    [CmdletBinding()]
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
                Write-Warning "Alert: Drive $($drive.DeviceID) is at $usedPercentage%"
            } else {
                $status = "OK"
            }

            # Create a Custom Object (data stays reusable)
            [PSCustomObject]@{
                DriveLetter = $drive.DeviceID
                Label       = $drive.VolumeName
                TotalSizeGB = [math]::Round($drive.Size / 1GB, 2)
                FreeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
                UsedPercent = $usedPercentage
                Status      = $status
            }
        }
    }

    # Return object array
    return $results
}
