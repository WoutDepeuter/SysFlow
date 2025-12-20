function Get-FolderSelection {
    param([string]$Description)

    Add-Type -AssemblyName System.Windows.Forms

    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.ShowNewFolderButton = $true

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}
# Import Modules
$MonitorModulePath = Join-Path $PSScriptRoot 'Modules\MonitorModule\MonitorModule.psm1'
$BackupModulePath  = Join-Path $PSScriptRoot 'Modules\BackupModule\BackupModule.psm1'
$ConfigPath = Join-Path $PSScriptRoot 'config.psd1'

# Load configuration
$Config = @{}
if (Test-Path $ConfigPath) {
    try {
        $Config = Import-PowerShellDataFile -Path $ConfigPath
    } catch {
        Write-Warning "Failed to load config: $_"
        $Config = @{ DefaultBackupDestination = '' }
    }
} else {
    $Config = @{ DefaultBackupDestination = '' }
}

# Import Monitor Module
if (Test-Path $MonitorModulePath) {
    Import-Module $MonitorModulePath -Force
}
# Import Backup Module
if (Test-Path $BackupModulePath) {
    Import-Module $BackupModulePath -Force
}

# Main Menu Function
function Show-MainMenu {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "   SYSFLOW AUTOMATION TOOL    " -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. System Monitoring"
    Write-Host "2. Backup Management"
    Write-Host "3. Software Management"
    Write-Host "4. Reporting"
    Write-Host "5. Settings"
    Write-Host "Q. Exit"
    Write-Host ""
}

# Submenu Functions for monitoring
function Show-StatusMenu {
    Write-Host "----- System Status Submenu -----" -ForegroundColor Green
    Write-Host "1. CPU Only"
    Write-Host "2. RAM Only"
    Write-Host "3. Storage Only"
    Write-Host "4. Show All Stats"
    Write-Host "5. System Uptime"
    Write-Host "6. Process Stats"
    Write-Host "B. Back to Main Menu"
}

# Submenu Functions for backup management
function Show-BackupMenu {
    Write-Host "----- Backup Management Submenu -----" -ForegroundColor Green
    Write-Host "1. Create Backup"
    Write-Host "2. Restore Backup"
    Write-Host "3. Remove Backup(s)"
    Write-Host "4. List Backups"
    Write-Host "B. Back to Main Menu"
}

function Show-SettingsMenu {
    Write-Host "----- Settings Menu -----" -ForegroundColor Green
    Write-Host "1. View Current Configuration"
    Write-Host "2. Set Default Backup Folder"
    Write-Host "3. Set Default Report Folder"
    Write-Host "4. Set Monitoring Thresholds"
    Write-Host "B. Back to Main Menu"
}

$MainExit = $false

do {
    Show-MainMenu
    $MainChoice = Read-Host "Make a selection"

    switch ($MainChoice) {

        '1' {
            $SubExit = $false
            do {
                Show-StatusMenu
                $SubChoice = Read-Host "Select stat option"
                Clear-Host

                switch ($SubChoice) {
                    '1' { Get-CPUStats -Threshold 70 | Format-Table -AutoSize }
                    '2' { Get-RamStats -Threshold 70 | Format-Table -AutoSize }
                    '3' { Get-StorageStats -Threshold 80 | Format-Table -AutoSize }
                    '4' {
                        Get-CPUStats -Threshold 70 | Format-Table -AutoSize
                        Get-RamStats -Threshold 70 | Format-Table -AutoSize
                        Get-StorageStats -Threshold 80 | Format-Table -AutoSize
                        Get-Uptime | Format-Table -AutoSize
                    }
                    '5' { Get-Uptime | Format-Table -AutoSize }
                    '6' { Get-ProcessStats -Threshold 500 | Format-Table -AutoSize }
                    'B' { $SubExit = $true }
                    'b' { $SubExit = $true }
                }
            } until ($SubExit)
        }

        '2' {
            $BackupExit = $false
            do {
                Show-BackupMenu
                $BackupChoice = Read-Host "Select backup option"
                Clear-Host

                switch ($BackupChoice) {

                    '1' {
                        $useGui = Read-Host "Use folder selection window? (Y/N)"

                        if ($useGui -match '^[Yy]$') {
                            $pathsInput = Get-FolderSelection "Select folder to backup"
                            $dest = Get-FolderSelection "Select backup destination"
                        } else {
                            $pathsInput = Read-Host "Enter path(s) to backup (comma-separated)"
                            
                            # Offer default if configured
                            if ($Config.DefaultBackupDestination) {
                                Write-Host "Default: $($Config.DefaultBackupDestination)" -ForegroundColor Gray
                                $dest = Read-Host "Backup destination (Enter for default)"
                                if (-not $dest) { $dest = $Config.DefaultBackupDestination }
                            } else {
                                $dest = Read-Host "Enter backup destination folder"
                            }
                        }

                        $name = Read-Host "Optional backup name"

                        if ($pathsInput -and $dest) {
                            $pathList = $pathsInput -split ',' | ForEach-Object { $_.Trim() }

                            if ([string]::IsNullOrWhiteSpace($name)) {
                                New-Backup -PathsToBackup $pathList -BackupDestination $dest
                            } else {
                                if (-not $name.EndsWith('.zip')) { $name += '.zip' }
                                New-Backup -PathsToBackup $pathList -BackupDestination $dest -BackupName $name
                            }
                        }
                    }

                    '2' {
                        $file = Read-Host "Enter backup zip path"
                        $restoreTo = Read-Host "Enter restore destination"
                        Restore-Backup -BackupFilePath $file -RestoreDestination $restoreTo
                    }

                    '3' {
                        if ($Config.DefaultBackupDestination) {
                            Write-Host "Default: $($Config.DefaultBackupDestination)" -ForegroundColor Gray
                            $dest = Read-Host "Backup folder (Enter for default)"
                            if (-not $dest) { $dest = $Config.DefaultBackupDestination }
                        } else {
                            $dest = Read-Host "Enter backup destination folder"
                        }
                        Remove-Backup -BackupDestination $dest
                    }

                    '4' {
                        if ($Config.DefaultBackupDestination) {
                            Write-Host "Default: $($Config.DefaultBackupDestination)" -ForegroundColor Gray
                            $dest = Read-Host "Backup folder (Enter for default)"
                            if (-not $dest) { $dest = $Config.DefaultBackupDestination }
                        } else {
                            $dest = Read-Host "Enter backup destination folder"
                        }
                        Remove-Backup -BackupDestination $dest -ListOnly |
                            Format-Table Index, Name, Size, Created -AutoSize
                    }

                    'B' { $BackupExit = $true }
                    'b' { $BackupExit = $true }
                }
            } until ($BackupExit)
        }

        '4' {
            Write-Host "Reporting Module coming soon..." -ForegroundColor Gray
            Pause
        }

        '5' {
            $SettingsExit = $false
            do {
                Show-SettingsMenu
                $SettingsChoice = Read-Host "Select settings option"
                Clear-Host

                switch ($SettingsChoice) {
                    '1' {
                        Write-Host "`n=== Current Configuration ===" -ForegroundColor Cyan
                        Write-Host ""
                        Write-Host "Backup Settings:" -ForegroundColor Yellow
                        Write-Host "  Default Backup Folder: $($Config.DefaultBackupDestination)" -ForegroundColor White
                        Write-Host ""
                        Write-Host "Report Settings:" -ForegroundColor Yellow
                        Write-Host "  Default Report Path: $($Config.DefaultReportPath)" -ForegroundColor White
                        Write-Host ""
                        Write-Host "Monitoring Thresholds:" -ForegroundColor Yellow
                        Write-Host "  CPU Threshold: $($Config.CPUThreshold)%" -ForegroundColor White
                        Write-Host "  RAM Threshold: $($Config.RAMThreshold)%" -ForegroundColor White
                        Write-Host "  Storage Threshold: $($Config.StorageThreshold)%" -ForegroundColor White
                        Write-Host "  Process Memory: $($Config.ProcessMemoryThreshold) MB" -ForegroundColor White
                        Write-Host ""
                        Pause
                    }

                    '2' {
                        Write-Host "`nCurrent default: $($Config.DefaultBackupDestination)" -ForegroundColor Cyan
                        $useGui = Read-Host "Use folder selection? (Y/N)"
                        
                        if ($useGui -match '^[Yy]$') {
                            $newPath = Get-FolderSelection "Select default backup folder"
                        } else {
                            $newPath = Read-Host "Enter new default backup folder"
                        }
                        
                        if ($newPath) {
                            $configContent = Get-Content $ConfigPath -Raw
                            $configContent = $configContent -replace "DefaultBackupDestination = '.*'", "DefaultBackupDestination = '$($newPath -replace '\\\\','\\\\')'"
                            $configContent | Set-Content $ConfigPath -Encoding UTF8
                            $Config.DefaultBackupDestination = $newPath
                            Write-Host "✓ Default backup folder set to: $newPath" -ForegroundColor Green
                        }
                        Pause
                    }

                    '3' {
                        Write-Host "`nCurrent default: $($Config.DefaultReportPath)" -ForegroundColor Cyan
                        $useGui = Read-Host "Use folder selection? (Y/N)"
                        
                        if ($useGui -match '^[Yy]$') {
                            $newPath = Get-FolderSelection "Select default report folder"
                        } else {
                            $newPath = Read-Host "Enter new default report folder"
                        }
                        
                        if ($newPath) {
                            $configContent = Get-Content $ConfigPath -Raw
                            $configContent = $configContent -replace "DefaultReportPath = '.*'", "DefaultReportPath = '$($newPath -replace '\\\\','\\\\')'"
                            $configContent | Set-Content $ConfigPath -Encoding UTF8
                            $Config.DefaultReportPath = $newPath
                            Write-Host "✓ Default report folder set to: $newPath" -ForegroundColor Green
                        }
                        Pause
                    }

                    '4' {
                        Write-Host "`n=== Set Monitoring Thresholds ===" -ForegroundColor Cyan
                        Write-Host "Current values shown in parentheses" -ForegroundColor Gray
                        Write-Host ""
                        
                        $cpu = Read-Host "CPU threshold % (current: $($Config.CPUThreshold))"
                        $ram = Read-Host "RAM threshold % (current: $($Config.RAMThreshold))"
                        $storage = Read-Host "Storage threshold % (current: $($Config.StorageThreshold))"
                        $process = Read-Host "Process memory MB (current: $($Config.ProcessMemoryThreshold))"
                        
                        $configContent = Get-Content $ConfigPath -Raw
                        if ($cpu) { 
                            $configContent = $configContent -replace "CPUThreshold = \d+", "CPUThreshold = $cpu"
                            $Config.CPUThreshold = [int]$cpu
                        }
                        if ($ram) { 
                            $configContent = $configContent -replace "RAMThreshold = \d+", "RAMThreshold = $ram"
                            $Config.RAMThreshold = [int]$ram
                        }
                        if ($storage) { 
                            $configContent = $configContent -replace "StorageThreshold = \d+", "StorageThreshold = $storage"
                            $Config.StorageThreshold = [int]$storage
                        }
                        if ($process) { 
                            $configContent = $configContent -replace "ProcessMemoryThreshold = \d+", "ProcessMemoryThreshold = $process"
                            $Config.ProcessMemoryThreshold = [int]$process
                        }
                        
                        if ($cpu -or $ram -or $storage -or $process) {
                            $configContent | Set-Content $ConfigPath -Encoding UTF8
                            Write-Host "✓ Thresholds updated successfully" -ForegroundColor Green
                        }
                        Pause
                    }

                    'B' { $SettingsExit = $true }
                    'b' { $SettingsExit = $true }
                }
            } until ($SettingsExit)
        }

        'Q' { $MainExit = $true }
        'q' { $MainExit = $true }
    }
} until ($MainExit)
