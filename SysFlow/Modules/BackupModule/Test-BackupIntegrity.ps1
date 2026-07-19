function Test-BackupIntegrity {
    <#
    .SYNOPSIS
        Tests the integrity of a backup zip file to ensure it is not corrupted.

    .DESCRIPTION
        The Test-BackupIntegrity function checks if the specified backup zip file can be opened and read without errors.
        It provides feedback on whether the backup file is valid or corrupted.

    .EXAMPLE
        Test-BackupIntegrity -BackupFilePath "C:\Backups\backup_2024-01-01.zip"
        Tests the integrity of the specified backup zip file.
        
    .OUTPUTS
        Boolean indicating whether the backup file is valid (True) or corrupted (False).

    .NOTES
        Author: SysFlow
        Version: 1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupFilePath
    )

    if (-not (Test-Path -Path $BackupFilePath -PathType Leaf)) {
        Write-Error "Backup file does not exist: $BackupFilePath"
        return $false
    }

    $isValid = $false
    $zip = $null

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $zip = [System.IO.Compression.ZipFile]::Open($BackupFilePath, [System.IO.Compression.ZipArchiveMode]::Read)
        

        $entryCount = $zip.Entries.Count
        
        Write-Verbose "Successfully read $entryCount entries from the backup."
        $isValid = $true
    }
    catch {
        Write-Warning "Backup file is corrupted or cannot be read: $BackupFilePath"
        Write-Verbose "Error details: $_"
        $isValid = $false
    }
    finally {
        if ($null -ne $zip) {
            $zip.Dispose()
        }
    }

    return $isValid
}

