# Function to restore a backup from a zip file that was created with New-Backup function

function Restore-Backup {
    <#
    .SYNOPSIS
        Restores a backup from a specified zip file to a target location.

    .DESCRIPTION
        The Restore-Backup function extracts the contents of a backup zip file created by the New-Backup function.
        It allows specifying a target directory for restoration and validates that the backup file exists.

    .PARAMETER BackupFilePath
        The full path to the backup zip file to restore.
        The file must exist and be a valid zip archive.

    .PARAMETER RestoreDestination
        The directory where the backup contents will be restored.
        If the directory doesn't exist, it will be created automatically.

    .EXAMPLE
        Restore-Backup -BackupFilePath "D:\Backups\Backup_20251207_143052.zip" -RestoreDestination "C:\RestoredData"
        
        Restores the contents of the specified backup zip file to C:\RestoredData.

    .EXAMPLE
        Restore-Backup -BackupFilePath "D:\Backups\Backup_20251207_143052.zip" -RestoreDestination "C:\RestoredData" -Verbose
        
        Restores with verbose output to see detailed restoration progress.

    .OUTPUTS
        PSCustomObject with restoration results:
        - BackupFile: Path to the restored backup file
        - RestoreDestination: Where the files were restored
        - FilesRestored: Number of files extracted
        - Success: Boolean indicating if restoration was successful

    .NOTES
        Author: SysFlow
        Version: 1.0
        Requires: PowerShell 5.0 or higher (for Expand-Archive)
    #>

    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupFilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RestoreDestination
    )

    # Validate that the backup file exists
    if (-not (Test-Path -Path $BackupFilePath)) {
        Write-Error "Backup file does not exist: $BackupFilePath"
        return
    }
    # Create the restore destination directory if it doesn't exist
    if (-not (Test-Path -Path $RestoreDestination)) {
        Write-Verbose "Creating restore destination: $RestoreDestination"
        New-Item -ItemType Directory -Path $RestoreDestination | Out-Null
    }
    try {
        Write-Verbose "Restoring backup from: $BackupFilePath to $RestoreDestination"
        # Extract the zip archive to the restore destination
        Expand-Archive -Path $BackupFilePath -DestinationPath $RestoreDestination -Force

        # Get the number of files restored
        $filesRestored = (Get-ChildItem -Path $RestoreDestination -Recurse | Measure-Object).Count

        # Return restoration result
        return [PSCustomObject]@{
            BackupFile        = $BackupFilePath
            RestoreDestination = $RestoreDestination
            FilesRestored     = $filesRestored
            Success           = $true
        }
    }
    catch {
        Write-Error "Failed to restore backup: $_"
        return [PSCustomObject]@{
            BackupFile        = $BackupFilePath
            RestoreDestination = $RestoreDestination
            FilesRestored     = 0
            Success           = $false
        }
    }


# End of Restore-Backup function
}
 



