function Remove-Backup {
    <#
    .SYNOPSIS
        Remove backup files interactively from a list or by path.

    .DESCRIPTION
        The Remove-Backup function displays all backups in a directory and allows you to select
        which ones to remove. You can also remove a specific backup by path.
        Use -ListOnly to view all backups without removing any.

    .PARAMETER BackupDestination
        Directory containing backup files to view and manage.
        If not specified, you will be prompted to select backups interactively.

    .PARAMETER BackupFilePath
        Specific backup file path to remove directly without showing the list.

    .PARAMETER ListOnly
        Display all backups without removing any. Use to preview what's available.

    .PARAMETER Force
        Remove selected backups without confirmation prompt.

    .EXAMPLE
        Remove-Backup -BackupDestination "D:\Backups"
        
        Displays all backups in D:\Backups and prompts you to select which ones to remove.

    .EXAMPLE
        Remove-Backup -BackupDestination "D:\Backups" -ListOnly
        
        Shows all backups without the option to remove them.

    .EXAMPLE
        Remove-Backup -BackupFilePath "D:\Backups\Backup_20251207_143052.zip"
        
        Removes a specific backup file directly.

    .EXAMPLE
        Remove-Backup -BackupDestination "D:\Backups" -Force
        
        Displays backups and removes selected ones without confirmation prompt.

    .OUTPUTS
        PSCustomObject with removal results:
        - Name: Backup filename
        - Path: Full path to backup
        - Size: Size of backup in MB
        - Created: Creation date
        - Status: Removal status (Removed/Skipped/Failed)

    .NOTES
        Author: SysFlow
        Version: 1.0
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(ParameterSetName='List')]
        [string]$BackupDestination,

        [Parameter(Mandatory=$true, ParameterSetName='ByPath')]
        [ValidateNotNullOrEmpty()]
        [string]$BackupFilePath,

        [Parameter(ParameterSetName='List')]
        [switch]$ListOnly,

        [switch]$Force
    )

    # Handle direct file removal
    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        if (Test-Path -Path $BackupFilePath) {
            try {
                Remove-Item -Path $BackupFilePath -Force -ErrorAction Stop
                Write-Host "✓ Backup file removed successfully: $BackupFilePath" -ForegroundColor Green
                return [PSCustomObject]@{
                    Name = (Split-Path $BackupFilePath -Leaf)
                    Path = $BackupFilePath
                    Status = "Removed"
                }
            }
            catch {
                Write-Error "Failed to remove backup file: $_"
                return
            }
        }
        else {
            Write-Warning "Backup file does not exist: $BackupFilePath"
            return
        }
    }

    # Handle list-based removal
    if (-not $BackupDestination) {
        $BackupDestination = Read-Host "Enter backup destination path"
    }

    # Validate backup destination
    if (-not (Test-Path -Path $BackupDestination)) {
        Write-Error "Backup destination does not exist: $BackupDestination"
        return
    }

    # Get all backups
    Write-Host "Scanning backups..." -ForegroundColor Cyan
    $backups = @(Get-ChildItem -Path $BackupDestination -File -Filter "*.zip" -ErrorAction SilentlyContinue | 
                 Sort-Object -Property CreationTime -Descending)

    if ($backups.Count -eq 0) {
        Write-Host "No backups found in: $BackupDestination" -ForegroundColor Yellow
        return
    }

    # Display backup list
    Write-Host "`n=== Available Backups ===" -ForegroundColor Cyan
    Write-Host ""
    
    $backupList = @()
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $backup = $backups[$i]
        $sizeMB = [math]::Round($backup.Length / 1MB, 2)
        $backupList += [PSCustomObject]@{
            Index = $i + 1
            Name = $backup.Name
            Size = $sizeMB
            Created = $backup.CreationTime
            Path = $backup.FullName
            PSIsContainer = $backup.PSIsContainer
        }
        
        Write-Host "$($i + 1). $($backup.Name)" -ForegroundColor White
        Write-Host "   Size: $sizeMB MB | Created: $($backup.CreationTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        Write-Host ""
    }

    # If ListOnly, exit here
    if ($ListOnly) {
        return $backupList
    }

    # Prompt for selection
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  Enter backup number(s) to remove (e.g., 1,3,5)" -ForegroundColor Yellow
    Write-Host "  Enter 'all' to remove all backups" -ForegroundColor Yellow
    Write-Host "  Enter 'quit' to cancel" -ForegroundColor Yellow
    Write-Host ""

    $selection = Read-Host "Select backups to remove"

    if ($selection -eq 'quit') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    # Parse selection
    $indicesToRemove = @()
    if ($selection -eq 'all') {
        $indicesToRemove = (1..$backups.Count)
    }
    else {
        $indicesToRemove = $selection -split ',' | ForEach-Object { [int]$_.Trim() } | Where-Object { $_ -ge 1 -and $_ -le $backups.Count }
    }

    if ($indicesToRemove.Count -eq 0) {
        Write-Warning "No valid selections made."
        return
    }

    # Display selected backups
    Write-Host "`nSelected backups for removal:" -ForegroundColor Yellow
    foreach ($index in $indicesToRemove) {
        $backup = $backups[$index - 1]
        Write-Host "  • $($backup.Name)" -ForegroundColor Red
    }

    # Ask for confirmation
    if (-not $Force) {
        Write-Host ""
        $confirm = Read-Host "Are you sure you want to remove these backups? (yes/no)"
        if ($confirm -ne 'yes') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }
    }

    # Remove selected backups
    Write-Host "`nRemoving backups..." -ForegroundColor Cyan
    $results = @()
    
    foreach ($index in $indicesToRemove) {
        $backup = $backups[$index - 1]
        try {
            Remove-Item -Path $backup.FullName -Force -ErrorAction Stop
            Write-Host "✓ Removed: $($backup.Name)" -ForegroundColor Green
            
            $results += [PSCustomObject]@{
                Name = $backup.Name
                Path = $backup.FullName
                Size = [math]::Round($backup.Length / 1MB, 2)
                Created = $backup.CreationTime
                Status = "Removed"
            }
        }
        catch {
            Write-Error "✗ Failed to remove $($backup.Name): $_"
            
            $results += [PSCustomObject]@{
                Name = $backup.Name
                Path = $backup.FullName
                Size = [math]::Round($backup.Length / 1MB, 2)
                Created = $backup.CreationTime
                Status = "Failed"
            }
        }
    }

    # Summary
    $removedCount = ($results | Where-Object { $_.Status -eq 'Removed' }).Count
    Write-Host "`n=== Removal Summary ===" -ForegroundColor Cyan
    Write-Host "Successfully removed: $removedCount/$($results.Count) backups" -ForegroundColor Green
    
    return $results
}
# End of Remove-Backup function
 

