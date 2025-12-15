function New-Backup {
    <#
    .SYNOPSIS
        Creates a compressed backup archive of specified paths.

    .DESCRIPTION
        The New-Backup function creates a timestamped ZIP archive of one or more specified paths.
        It validates that all source paths exist, creates the destination directory if needed,
        and returns metadata about the created backup.

    .PARAMETER PathsToBackup
        One or more file or folder paths to include in the backup.
        All paths must exist or the function will fail.

    .PARAMETER BackupDestination
        The directory where the backup ZIP file will be created.
        If the directory doesn't exist, it will be created automatically.

    .PARAMETER BackupName
        Optional. The name of the backup ZIP file.
        Default: "Backup_yyyyMMdd_HHmmss.zip" (e.g., Backup_20251207_143052.zip)

    .EXAMPLE
        New-Backup -PathsToBackup "C:\Users\depeu\Documents" -BackupDestination "D:\Backups"
        
        Creates a timestamped backup of the Documents folder in D:\Backups.

    .EXAMPLE
        New-Backup -PathsToBackup @("C:\Project1", "C:\Project2") -BackupDestination "D:\Backups" -BackupName "Projects.zip"
        
        Creates a backup named "Projects.zip" containing both Project1 and Project2 folders.

    .OUTPUTS
        PSCustomObject with properties:
        - BackupPath: Full path to the created ZIP file
        - CreatedAt: Timestamp when backup was created
        - Size: Size of the backup file in bytes

    .NOTES
        Author: SysFlow
        Version: 1.0
        Requires: PowerShell 5.0 or higher (for Compress-Archive)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$PathsToBackup,
        
        [Parameter(Mandatory=$true)]
        [string]$BackupDestination,
        
        [string]$BackupName = "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    )

    # Validate that all paths exist
    foreach ($path in $PathsToBackup) {
        if (-not (Test-Path -Path $path)) {
            Write-Error "Path does not exist: $path"
            return
        }
    }

    # Check if the destination directory exists, if not create it
    if (-not (Test-Path -Path $BackupDestination)) {
        Write-Verbose "Creating backup destination: $BackupDestination"
        New-Item -ItemType Directory -Path $BackupDestination | Out-Null
    }

    # Create the full path for the backup file
    $BackupFilePath = Join-Path -Path $BackupDestination -ChildPath $BackupName

    try {
        Write-Verbose "Creating backup at: $BackupFilePath"
        # Create a zip archive of the specified paths
        Compress-Archive -Path $PathsToBackup -DestinationPath $BackupFilePath -Force
        Write-Host "Backup created successfully at: $BackupFilePath" -ForegroundColor Green
        
        # Return backup info
        return [PSCustomObject]@{
            BackupPath = $BackupFilePath
            CreatedAt = Get-Date
            Size = (Get-Item $BackupFilePath).Length
        }
    }
    catch {
        Write-Error "Failed to create backup: $_"
    }
}
# End of New-Backup function
 











