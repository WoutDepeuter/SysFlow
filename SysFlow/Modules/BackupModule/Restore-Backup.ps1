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

    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupFilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RestoreDestination,

        [Parameter()]
        [switch]$UseManifestPaths
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
        if ($UseManifestPaths) {
            Write-Verbose "Restoring using manifest paths from: $BackupFilePath"

            # Extract to temp first to read manifest and map items
            $tempExtract = Join-Path $env:TEMP ("SysFlow_Restore_" + [IO.Path]::GetFileNameWithoutExtension($BackupFilePath) + "_" + [Guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $tempExtract | Out-Null
            Expand-Archive -Path $BackupFilePath -DestinationPath $tempExtract -Force

            # Find manifest (support randomized temp manifest names)
            $manifestFile = Get-ChildItem -Path $tempExtract -Filter "backup-manifest*.json" -File -Recurse | Select-Object -First 1
            if (-not $manifestFile) {
                Write-Warning "No manifest found in backup. Falling back to destination restore."
                Expand-Archive -Path $BackupFilePath -DestinationPath $RestoreDestination -Force
                $filesRestored = (Get-ChildItem -Path $RestoreDestination -Recurse | Measure-Object).Count
                return [PSCustomObject]@{
                    BackupFile         = $BackupFilePath
                    RestoreDestination = $RestoreDestination
                    FilesRestored      = $filesRestored
                    UsedManifest       = $false
                    Success            = $true
                }
            }

            $manifestJson = (Get-Content -Path $manifestFile.FullName -Raw) | ConvertFrom-Json
            $sources = @($manifestJson.Sources)

            $filesRestored = 0
            foreach ($src in $sources) {
                if ([string]::IsNullOrWhiteSpace($src)) { continue }
                $leaf = Split-Path -Path $src -Leaf
                # Attempt to locate the extracted counterpart
                $extracted = Get-ChildItem -Path $tempExtract -Recurse -Force | Where-Object { $_.Name -eq $leaf } | Select-Object -First 1
                if (-not $extracted) {
                    Write-Warning "Could not locate '$leaf' in extracted archive for source '$src'"
                    continue
                }

                if (Test-Path -LiteralPath $src -PathType Container) {
                    # Restore directory contents to original path
                    if ($PSCmdlet.ShouldProcess($src, "Restore directory contents")) {
                        New-Item -ItemType Directory -Path $src -ErrorAction SilentlyContinue | Out-Null
                        $toCopy = Join-Path $extracted.FullName '*'
                        Copy-Item -Path $toCopy -Destination $src -Recurse -Force -ErrorAction SilentlyContinue
                        $filesRestored += (Get-ChildItem -Path $extracted.FullName -Recurse | Measure-Object).Count
                    }
                } else {
                    # Restore file to its original directory
                    $targetDir = Split-Path -Path $src -Parent
                    if ($PSCmdlet.ShouldProcess($src, "Restore file")) {
                        New-Item -ItemType Directory -Path $targetDir -ErrorAction SilentlyContinue | Out-Null
                        Copy-Item -Path $extracted.FullName -Destination $targetDir -Force -ErrorAction SilentlyContinue
                        $filesRestored += 1
                    }
                }
            }

            # Return result for manifest-based restore
            return [PSCustomObject]@{
                BackupFile         = $BackupFilePath
                RestoreDestination = "Original paths (manifest)"
                FilesRestored      = $filesRestored
                Sources            = $sources
                UsedManifest       = $true
                Success            = $true
            }
        }
        else {
            Write-Verbose "Restoring backup from: $BackupFilePath to $RestoreDestination"
            Expand-Archive -Path $BackupFilePath -DestinationPath $RestoreDestination -Force

            # Try to surface manifest info if present (support wildcard name)
            $manifestFile = Get-ChildItem -Path $RestoreDestination -Filter "backup-manifest*.json" -File -Recurse | Select-Object -First 1
            $sources = $null
            if ($manifestFile) {
                try {
                    $manifestJson = (Get-Content -Path $manifestFile.FullName -Raw)
                    $sources = $manifestJson | ConvertFrom-Json | Select-Object -ExpandProperty Sources -ErrorAction SilentlyContinue
                } catch {
                    Write-Warning "Could not parse backup manifest: $_"
                }
            }

            $filesRestored = (Get-ChildItem -Path $RestoreDestination -Recurse | Measure-Object).Count
            return [PSCustomObject]@{
                BackupFile         = $BackupFilePath
                RestoreDestination = $RestoreDestination
                FilesRestored      = $filesRestored
                Sources            = $sources
                UsedManifest       = $false
                Success            = $true
            }
        }
    }
    catch {
        Write-Error "Failed to restore backup: $_"
        return [PSCustomObject]@{
            BackupFile         = $BackupFilePath
            RestoreDestination = $RestoreDestination
            FilesRestored      = 0
            Success            = $false
        }
    }


# End of Restore-Backup function
}
 



