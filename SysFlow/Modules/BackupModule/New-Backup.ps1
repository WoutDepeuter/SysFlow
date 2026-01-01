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
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
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
        Write-Verbose "Preparing to create backup at: $BackupFilePath"

        # Build a small manifest with sources and metadata
        $manifest = [PSCustomObject]@{
            Sources    = $PathsToBackup
            CreatedAt  = (Get-Date).ToString('o')
            Machine    = $env:COMPUTERNAME
            User       = $env:USERNAME
            Tool       = 'SysFlow New-Backup'
            Version    = '1.0'
        }

        $tempManifestPath = Join-Path $env:TEMP ("backup-manifest_" + [Guid]::NewGuid().ToString() + ".json")
        $manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $tempManifestPath -Encoding UTF8

        if ($PSCmdlet.ShouldProcess($BackupFilePath, 'Create backup archive')) {
            Write-Progress -Activity "Creating backup" -Status "Compressing files..." -PercentComplete 0
            
            # Use .NET ZipFile for large file support (>2GB)
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            
            # Remove existing backup if it exists
            if (Test-Path $BackupFilePath) {
                Remove-Item $BackupFilePath -Force
            }
            
            # Create the zip archive
            $zip = [System.IO.Compression.ZipFile]::Open($BackupFilePath, [System.IO.Compression.ZipArchiveMode]::Create)
            
            try {
                # Add each source path to the archive
                foreach ($sourcePath in $PathsToBackup) {
                    $sourcePath = (Resolve-Path $sourcePath).Path
                    
                    if (Test-Path $sourcePath -PathType Container) {
                        # It's a directory - add all files recursively
                        $files = Get-ChildItem -Path $sourcePath -Recurse -File
                        $totalFiles = $files.Count
                        $fileIndex = 0
                        
                        foreach ($file in $files) {
                            $fileIndex++
                            $relativePath = $file.FullName.Substring($sourcePath.Length).TrimStart('\', '/')
                            $entryName = (Split-Path -Leaf $sourcePath) + '\' + $relativePath
                            
                            Write-Progress -Activity "Creating backup" -Status "Adding: $($file.Name)" -PercentComplete (($fileIndex / $totalFiles) * 100)
                            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
                        }
                    }
                    else {
                        # It's a file - add it directly
                        $fileName = Split-Path -Leaf $sourcePath
                        Write-Progress -Activity "Creating backup" -Status "Adding: $fileName"
                        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $sourcePath, $fileName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
                    }
                }
                
                # Add manifest file
                $manifestName = Split-Path -Leaf $tempManifestPath
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $tempManifestPath, $manifestName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            }
            finally {
                $zip.Dispose()
            }
            
            Write-Progress -Activity "Creating backup" -Completed -Status "Done"
            Write-Host "Backup created successfully at: $BackupFilePath" -ForegroundColor Green
        } else {
            Write-Verbose "WhatIf: Skipped creating backup at $BackupFilePath"
        }

        # Cleanup temp manifest
        if (Test-Path $tempManifestPath) { Remove-Item -Path $tempManifestPath -ErrorAction SilentlyContinue }
        
        # Return backup info (even on WhatIf, reflect intended path)
        $size = (Test-Path $BackupFilePath) ? (Get-Item $BackupFilePath).Length : 0
        return [PSCustomObject]@{
            BackupPath = $BackupFilePath
            CreatedAt = Get-Date
            Size = $size
        }
    }
    catch {
        Write-Error "Failed to create backup: $_"
    }
}
# End of New-Backup function
 











