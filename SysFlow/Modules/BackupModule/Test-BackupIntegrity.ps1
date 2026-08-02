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
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('BackupPath', 'FullName')]
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


function Test-BackupIntegrityAfterCreation {
    <#
    .SYNOPSIS
        Tests the integrity of a backup archive immediately after creation.
    .DESCRIPTION
        This is a wrapper function that calls Test-BackupIntegrity to verify
        the backup zip file and outputs the result directly to the console.
    .PARAMETER BackupFilePath
        The full path to the newly created backup zip file.
    .EXAMPLE
        Test-BackupIntegrityAfterCreation -BackupFilePath "C:\Backups\backup.zip"
    #>

    param (
        [Parameter(Mandatory=$true)]
        [string]$BackupFilePath
    )

    Write-Verbose "Testing integrity of backup: $BackupFilePath"
    $isValid = Test-BackupIntegrity -BackupFilePath $BackupFilePath

    if ($isValid) {
        Write-Host "Backup integrity check passed for: $BackupFilePath"
    } else {
        Write-Host "Backup integrity check failed for: $BackupFilePath"
    }
}

