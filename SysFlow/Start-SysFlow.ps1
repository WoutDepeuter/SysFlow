# Folder selection GUI function
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
$BackupModulePath = Join-Path $PSScriptRoot 'Modules\BackupModule\BackupModule.psm1'
$SoftwareModulePath = Join-Path $PSScriptRoot 'Modules\SoftwareModule\SoftwareModule.psm1'
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

# Ensure default package manager is available in config at runtime
if (-not ($Config.ContainsKey('DefaultPackageManager')) -or [string]::IsNullOrWhiteSpace($Config.DefaultPackageManager)) {
    $Config.DefaultPackageManager = 'choco'
}

# Helper: return a threshold value from config or fall back to a sane default
function Get-ThresholdValue {
    param(
        [Parameter(Mandatory)][int]$Default,
        [Parameter(Mandatory)]$Value
    )

    if ($null -ne $Value -and [int]$Value -gt 0) {
        return [int]$Value
    }

    return $Default
}

# Import Monitor Module
if (Test-Path $MonitorModulePath) {
    Import-Module $MonitorModulePath -Force
}
# Import Backup Module
if (Test-Path $BackupModulePath) {
    Import-Module $BackupModulePath -Force
}
# Import Software Module
if (Test-Path $SoftwareModulePath) {
    Import-Module $SoftwareModulePath -Force
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

# Submenu Functions for settings
function Show-SettingsMenu {
    Write-Host "----- Settings Menu -----" -ForegroundColor Green
    Write-Host "1. View Current Configuration"
    Write-Host "2. Set Default Backup Destination Folder"
    Write-Host "3. Set Default Source Folder to Backup"
    Write-Host "4. Set Default Report Folder"
    Write-Host "5. Set Monitoring Thresholds"
    Write-Host "6. Set Default Package Manager"
    Write-Host "B. Back to Main Menu"
}

function Show-SoftwareMenu {
    Write-Host "----- Software Management Submenu -----" -ForegroundColor Green
    Write-Host "1. List Installed Software"
    Write-Host "2. Install Software"
    Write-Host "3. Update Software"
    Write-Host "4. Uninstall Software"
    Write-Host "B. Back to Main Menu"
}

# Main driver
function Start-SysFlow {
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
                        '1' {
                            $stats = Get-CPUStats -Threshold (Get-ThresholdValue -Default 70 -Value $Config.CPUThreshold)
                            $stats | Format-Table -AutoSize
                            Export-StatToCsv -Stats $stats -OutputFilePath (Join-Path $Config.DefaultReportPath "CPU_History.csv")
                            Write-SysFlowLog -LogLevel "Info" -Message "CPU stats gecontroleerd. Load: $($stats.LoadPercentage)%" -LogFilePath $Config.LogPath
                        }

                        '2' {
                            $stats = Get-RamStats -Threshold (Get-ThresholdValue -Default 70 -Value $Config.RAMThreshold)
                            Export-StatToCsv -Stats $stats -OutputFilePath (Join-Path $Config.DefaultReportPath "RAM_History.csv")
                            Write-SysFlowLog -LogLevel "Info" -Message "RAM stats gecontroleerd. Vrij: $($stats.Free) GB" -LogFilePath $Config.LogPath
                        }

                        '3' {
                            $stats = Get-StorageStats -Threshold (Get-ThresholdValue -Default 80 -Value $Config.StorageThreshold)
                            $stats | Format-Table -AutoSize
                            Export-StatToCsv -Stats $stats -OutputFilePath (Join-Path $Config.DefaultReportPath "Storage_History.csv")
                            Write-SysFlowLog -LogLevel "Info" -Message "Storage gecontroleerd voor $($stats.Count) schijven." -LogFilePath $Config.LogPath
                        }

                        '4' {
                            $cpu = Get-CPUStats -Threshold (Get-ThresholdValue -Default 70 -Value $Config.CPUThreshold)
                            $ram = Get-RamStats -Threshold (Get-ThresholdValue -Default 70 -Value $Config.RAMThreshold)
                            $storage = Get-StorageStats -Threshold (Get-ThresholdValue -Default 80 -Value $Config.StorageThreshold)
                            $uptime = Get-Uptime

                            Write-Host "`n--- CPU Details ---" -ForegroundColor Cyan
                            $cpu | Format-Table -AutoSize

                            Write-Host "`n--- RAM Details ---" -ForegroundColor Cyan
                            $ram | Format-Table -AutoSize

                            Write-Host "--- Storage Details ---" -ForegroundColor Cyan
                            $storage | Format-Table -AutoSize

                            Write-Host "--- Uptime Details ---" -ForegroundColor Cyan
                            $uptime | Format-Table -AutoSize

                            Export-StatToCsv -Stats $cpu -OutputFilePath (Join-Path $Config.DefaultReportPath "CPU_History.csv")
                            Export-StatToCsv -Stats $ram -OutputFilePath (Join-Path $Config.DefaultReportPath "RAM_History.csv")
                            Export-StatToCsv -Stats $storage -OutputFilePath (Join-Path $Config.DefaultReportPath "Storage_History.csv")

                            Write-SysFlowLog -LogLevel "Info" -Message "Volledige systeemscan uitgevoerd." -LogFilePath $Config.LogPath
                        }

                        '5' {
                            $stats = Get-Uptime
                            $stats | Format-Table -AutoSize
                            Write-SysFlowLog -LogLevel "Info" -Message "Uptime: $($stats.Days) dagen, $($stats.Hours) uur." -LogFilePath $Config.LogPath
                        }

                        '6' {
                            $stats = Get-ProcessStats -Threshold (Get-ThresholdValue -Default 500 -Value $Config.ProcessMemoryThreshold)
                            $highMem = $stats | Where-Object { $_.MemoryUsageMB -ge (Get-ThresholdValue -Default 500 -Value $Config.ProcessMemoryThreshold) }

                            if ($highMem) {
                                $highMem | Format-Table -AutoSize
                                Write-SysFlowLog -LogLevel "Warning" -Message "Hoog geheugenverbruik: $($highMem.Count) processen." -LogFilePath $Config.LogPath
                            } else {
                                Write-SysFlowLog -LogLevel "Info" -Message "Processen gecontroleerd, geen uitschieters." -LogFilePath $Config.LogPath
                            }

                            if ($stats) {
                                Export-StatToCsv -Stats $stats -OutputFilePath (Join-Path $Config.DefaultReportPath "Process_History.csv")
                            }
                        }

                        'B' { $SubExit = $true }
                        'b' { $SubExit = $true }
                    }
                } until ($SubExit)
            }

            # Switch for backup management
            '2' {
                $BackupExit = $false
                do {
                    Show-BackupMenu
                    $BackupChoice = Read-Host "Select backup option"
                    Clear-Host

                    switch ($BackupChoice) {
                        # Create backup
                        '1' {
                            Write-SysFlowLog -LogLevel "Info" -Message "Backup creation initiated" -LogFilePath $Config.LogPath
                            
                            # Ask for source path
                            if ($Config.DefaultBackupSource) {
                                Write-Host "\nDefault source folder: $($Config.DefaultBackupSource)" -ForegroundColor Cyan
                                $useDefaultSource = Read-Host "Use default source folder? (Y/N)"
                                
                                if ($useDefaultSource -match '^[Yy]$') {
                                    $pathsInput = $Config.DefaultBackupSource
                                } else {
                                    $useGui = Read-Host "Use folder selection window? (Y/N)"
                                    if ($useGui -match '^[Yy]$') {
                                        $pathsInput = Get-FolderSelection "Select folder to backup"
                                    } else {
                                        $pathsInput = Read-Host "Enter path(s) to backup (comma-separated)"
                                    }
                                }
                            } else {
                                $useGui = Read-Host "Use folder selection window for source? (Y/N)"
                                if ($useGui -match '^[Yy]$') {
                                    $pathsInput = Get-FolderSelection "Select folder to backup"
                                } else {
                                    $pathsInput = Read-Host "Enter path(s) to backup (comma-separated)"
                                }
                            }
                            
                            # Ask about destination
                            if ($Config.DefaultBackupDestination) {
                                Write-Host "`nDefault backup folder: $($Config.DefaultBackupDestination)" -ForegroundColor Cyan
                                $useDefault = Read-Host "Use default backup folder? (Y/N)"
                                
                                if ($useDefault -match '^[Yy]$') {
                                    $dest = $Config.DefaultBackupDestination
                                } else {
                                    $useGuiDest = Read-Host "Use folder selection for destination? (Y/N)"
                                    if ($useGuiDest -match '^[Yy]$') {
                                        $dest = Get-FolderSelection "Select backup destination"
                                    } else {
                                        $dest = Read-Host "Enter backup destination folder"
                                    }
                                }
                            } else {
                                $useGuiDest = Read-Host "Use folder selection for destination? (Y/N)"
                                if ($useGuiDest -match '^[Yy]$') {
                                    $dest = Get-FolderSelection "Select backup destination"
                                } else {
                                    $dest = Read-Host "Enter backup destination folder"
                                }
                            }

                            $name = Read-Host "Optional backup name"

                            if ($pathsInput -and $dest) {
                                $pathList = $pathsInput -split ',' | ForEach-Object { $_.Trim() }
                                $backupDetails = "Source: $pathsInput | Destination: $dest | Name: $(if ([string]::IsNullOrWhiteSpace($name)) { 'Auto-generated' } else { $name })"
                                Write-SysFlowLog -LogLevel "Info" -Message "Creating backup" -Details $backupDetails -LogFilePath $Config.LogPath

                                if ([string]::IsNullOrWhiteSpace($name)) {
                                    New-Backup -PathsToBackup $pathList -BackupDestination $dest
                                } else {
                                    if (-not $name.EndsWith('.zip')) { $name += '.zip' }
                                    New-Backup -PathsToBackup $pathList -BackupDestination $dest -BackupName $name
                                }
                                Write-SysFlowLog -LogLevel "Info" -Message "Backup created successfully" -LogFilePath $Config.LogPath
                            } else {
                                Write-SysFlowLog -LogLevel "Warning" -Message "Backup cancelled: missing source or destination" -LogFilePath $Config.LogPath
                            }
                        }

                        '2' {
                            Write-SysFlowLog -LogLevel "Info" -Message "Restore backup initiated" -LogFilePath $Config.LogPath
                            $file = $null
                            if ($Config.DefaultBackupDestination) {
                                Write-Host "\nDefault backup folder: $($Config.DefaultBackupDestination)" -ForegroundColor Cyan
                                $useDefaultFolder = Read-Host "Select a backup from the default folder? (Y/N)"
                                if ($useDefaultFolder -match '^[Yy]$') {
                                    try {
                                        $zips = Get-ChildItem -Path $Config.DefaultBackupDestination -Filter "*.zip" -File | Sort-Object LastWriteTime -Descending
                                    } catch {
                                        Write-Warning "Could not read default backup folder: $_"
                                        Write-SysFlowLog -LogLevel "Error" -Message "Failed to read backup folder" -Details $_ -LogFilePath $Config.LogPath
                                        $zips = @()
                                    }

                                    if ($zips.Count -eq 0) {
                                        Write-Host "No backup ZIPs found in default folder." -ForegroundColor Yellow
                                        Write-SysFlowLog -LogLevel "Warning" -Message "No backup files found" -LogFilePath $Config.LogPath
                                    } else {
                                        Write-Host "\nAvailable backups:" -ForegroundColor Cyan
                                        for ($i = 0; $i -lt $zips.Count; $i++) {
                                            $idx = $i + 1
                                            Write-Host ("{0}. {1} ({2})" -f $idx, $zips[$i].Name, $zips[$i].LastWriteTime)
                                        }
                                        $choice = Read-Host "Enter number to select backup"
                                        if ($choice -match '^[0-9]+$' -and [int]$choice -ge 1 -and [int]$choice -le $zips.Count) {
                                            $file = $zips[[int]$choice - 1].FullName
                                            Write-Host "Selected: $file" -ForegroundColor Green
                                            Write-SysFlowLog -LogLevel "Info" -Message "Backup selected for restore" -Details "File: $file" -LogFilePath $Config.LogPath
                                        } else {
                                            Write-Host "Invalid selection; falling back to manual path." -ForegroundColor Yellow
                                            Write-SysFlowLog -LogLevel "Warning" -Message "Invalid backup selection" -LogFilePath $Config.LogPath
                                        }
                                    }
                                }
                            }

                            if (-not $file) {
                                $file = Read-Host "Enter backup zip path"
                            }

                            $useManifest = Read-Host "Use manifest paths to restore to original locations? (Y/N)"
                            if ($useManifest -match '^[Yy]$') {
                                Write-SysFlowLog -LogLevel "Info" -Message "Restoring backup using manifest paths" -Details "File: $file" -LogFilePath $Config.LogPath
                                Restore-Backup -BackupFilePath $file -UseManifestPaths
                                Write-SysFlowLog -LogLevel "Info" -Message "Restore completed" -LogFilePath $Config.LogPath
                            } else {
                                $restoreTo = Read-Host "Enter restore destination"
                                Write-SysFlowLog -LogLevel "Info" -Message "Restoring backup to custom location" -Details "File: $file | Destination: $restoreTo" -LogFilePath $Config.LogPath
                                Restore-Backup -BackupFilePath $file -RestoreDestination $restoreTo
                                Write-SysFlowLog -LogLevel "Info" -Message "Restore completed" -LogFilePath $Config.LogPath
                            }
                        }

                        '3' {
                            Write-SysFlowLog -LogLevel "Info" -Message "Backup removal initiated" -LogFilePath $Config.LogPath
                            if ($Config.DefaultBackupDestination) {
                                Write-Host "\nDefault backup folder: $($Config.DefaultBackupDestination)" -ForegroundColor Cyan
                                $useDefault = Read-Host "Use default backup folder? (Y/N)"
                                
                                if ($useDefault -match '^[Yy]$') {
                                    $dest = $Config.DefaultBackupDestination
                                } else {
                                    $dest = Read-Host "Enter backup folder path"
                                }
                            } else {
                                $dest = Read-Host "Enter backup destination folder"
                            }
                            Write-SysFlowLog -LogLevel "Info" -Message "Removing backups" -Details "Destination: $dest" -LogFilePath $Config.LogPath
                            Remove-Backup -BackupDestination $dest
                            Write-SysFlowLog -LogLevel "Info" -Message "Backup removal completed" -LogFilePath $Config.LogPath
                        }

                        '4' {
                            Write-SysFlowLog -LogLevel "Info" -Message "Listing backups" -LogFilePath $Config.LogPath
                            if ($Config.DefaultBackupDestination) {
                                Write-Host "\nDefault backup folder: $($Config.DefaultBackupDestination)" -ForegroundColor Cyan
                                $useDefault = Read-Host "Use default backup folder? (Y/N)"
                                
                                if ($useDefault -match '^[Yy]$') {
                                    $dest = $Config.DefaultBackupDestination
                                } else {
                                    $dest = Read-Host "Enter backup folder path"
                                }
                            } else {
                                $dest = Read-Host "Enter backup destination folder"
                            }
                            $backupList = Remove-Backup -BackupDestination $dest -ListOnly
                            $backupList | Format-Table Index, Name, Size, Created -AutoSize
                            Write-SysFlowLog -LogLevel "Info" -Message "Backups listed" -Details "Found $($backupList.Count) backups" -LogFilePath $Config.LogPath
                        }

                        'B' { $BackupExit = $true }
                        'b' { $BackupExit = $true }
                    }
                } until ($BackupExit)
            }

            '3' {
                $SoftwareExit = $false
                do {
                    Show-SoftwareMenu
                    $SoftChoice = Read-Host "Select software option"
                    Clear-Host

                    switch ($SoftChoice) {
                        '1' {
                            Write-Host "Listing installed software..." -ForegroundColor Cyan
                            Write-SysFlowLog -LogLevel "Info" -Message "Listing installed software" -LogFilePath $Config.LogPath
                            $softwareList = Get-SoftwareList | Sort-Object Name
                            $softwareList | Format-Table Name, Version, Publisher -AutoSize
                            Write-SysFlowLog -LogLevel "Info" -Message "Software list displayed" -Details "Found $($softwareList.Count) applications" -LogFilePath $Config.LogPath
                            Pause
                        }
                        '2' {
                            $name = Read-Host "Enter software name or ID"
                            if (-not [string]::IsNullOrWhiteSpace($name)) {
                                $defaultMgr = if ([string]::IsNullOrWhiteSpace($Config.DefaultPackageManager)) { 'winget' } else { $Config.DefaultPackageManager }
                                $mgr = Read-Host "Manager (winget/choco, default $defaultMgr)"
                                if ([string]::IsNullOrWhiteSpace($mgr)) { $mgr = $defaultMgr }
                                Write-SysFlowLog -LogLevel "Info" -Message "Installing software" -Details "Name: $name | Manager: $mgr" -LogFilePath $Config.LogPath
                                Install-Software -SoftwareName $name -Manager $mgr
                                Write-SysFlowLog -LogLevel "Info" -Message "Software installation completed" -LogFilePath $Config.LogPath
                            } else {
                                Write-SysFlowLog -LogLevel "Warning" -Message "Software installation cancelled: no name provided" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }
                        '3' {
                            $name = Read-Host "Enter software name or ID"
                            $defaultMgr = if ([string]::IsNullOrWhiteSpace($Config.DefaultPackageManager)) { 'winget' } else { $Config.DefaultPackageManager }
                            $mgr = Read-Host "Manager (winget/choco, default $defaultMgr)"
                            if ([string]::IsNullOrWhiteSpace($mgr)) { $mgr = $defaultMgr }

                            if ([string]::IsNullOrWhiteSpace($name)) {
                                $showList = Read-Host "No name entered. Show installed software list? (Y/N)"
                                Write-SysFlowLog -LogLevel "Warning" -Message "Software update cancelled: no name provided" -LogFilePath $Config.LogPath
                                if ($showList -match '^[Yy]$') {
                                    Get-SoftwareList | Sort-Object Name | Format-Table Name, Version -AutoSize
                                }
                            } else {
                                Write-SysFlowLog -LogLevel "Info" -Message "Updating software" -Details "Name: $name | Manager: $mgr" -LogFilePath $Config.LogPath
                                Update-Software -PackageName $name -Manager $mgr
                                Write-SysFlowLog -LogLevel "Info" -Message "Software update completed" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }
                        '4' {
                            $name = Read-Host "Enter software name or ID"
                            $defaultMgr = if ([string]::IsNullOrWhiteSpace($Config.DefaultPackageManager)) { 'winget' } else { $Config.DefaultPackageManager }
                            $mgr = Read-Host "Manager (winget/choco, default $defaultMgr)"
                            if ([string]::IsNullOrWhiteSpace($mgr)) { $mgr = $defaultMgr }

                            if ([string]::IsNullOrWhiteSpace($name)) {
                                $showList = Read-Host "No name entered. Show installed software list? (Y/N)"
                                Write-SysFlowLog -LogLevel "Warning" -Message "Software uninstall cancelled: no name provided" -LogFilePath $Config.LogPath
                                if ($showList -match '^[Yy]$') {
                                    Get-SoftwareList | Sort-Object Name | Format-Table Name, Version -AutoSize
                                }
                            } else {
                                Write-SysFlowLog -LogLevel "Info" -Message "Uninstalling software" -Details "Name: $name | Manager: $mgr" -LogFilePath $Config.LogPath
                                Uninstall-Software -PackageName $name -Manager $mgr
                                Write-SysFlowLog -LogLevel "Info" -Message "Software uninstall completed" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }
                        'B' { $SoftwareExit = $true }
                        'b' { $SoftwareExit = $true }
                    }
                } until ($SoftwareExit)
            }

            '4' {
                Write-Host "Reporting Module coming soon..." -ForegroundColor Gray
                Write-SysFlowLog -LogLevel "Info" -Message "Reporting module accessed (not yet implemented)" -LogFilePath $Config.LogPath
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
                            Write-Host "\n=== Current Configuration ===" -ForegroundColor Cyan
                            Write-Host ""
                            Write-Host "Backup Settings:" -ForegroundColor Yellow
                            Write-Host "  Default Backup Destination: $($Config.DefaultBackupDestination)" -ForegroundColor White
                            Write-Host "  Default Source Folder: $($Config.DefaultBackupSource)" -ForegroundColor White
                            Write-Host ""
                            Write-Host "Software Settings:" -ForegroundColor Yellow
                            Write-Host "  Default Package Manager: $($Config.DefaultPackageManager)" -ForegroundColor White
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
                            Write-SysFlowLog -LogLevel "Info" -Message "Configuration viewed" -LogFilePath $Config.LogPath
                            Pause
                        }

                        '2' {
                            Write-Host "\nCurrent default destination: $($Config.DefaultBackupDestination)" -ForegroundColor Cyan
                            $useGui = Read-Host "Use folder selection? (Y/N)"
                            
                            if ($useGui -match '^[Yy]$') {
                                $newPath = Get-FolderSelection "Select default backup folder"
                            } else {
                                $newPath = Read-Host "Enter new default backup folder"
                            }
                            
                            if ($newPath) {
                                $configContent = Get-Content $ConfigPath -Raw
                                $configContent = $configContent -replace "DefaultBackupDestination = '.*'", "DefaultBackupDestination = '$($newPath -replace '\\','\\')'"
                                $configContent | Set-Content $ConfigPath -Encoding UTF8
                                $Config.DefaultBackupDestination = $newPath
                                Write-Host "✓ Default backup folder set to: $newPath" -ForegroundColor Green
                                Write-SysFlowLog -LogLevel "Info" -Message "Default backup destination updated" -Details "New path: $newPath" -LogFilePath $Config.LogPath
                            } else {
                                Write-SysFlowLog -LogLevel "Warning" -Message "Default backup destination change cancelled" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }

                        '3' {
                            Write-Host "\nCurrent default source: $($Config.DefaultBackupSource)" -ForegroundColor Cyan
                            $useGui = Read-Host "Use folder selection? (Y/N)"
                            
                            if ($useGui -match '^[Yy]$') {
                                $newPath = Get-FolderSelection "Select default source folder to backup"
                            } else {
                                $newPath = Read-Host "Enter new default source folder"
                            }
                            
                            if ($newPath) {
                                $configContent = Get-Content $ConfigPath -Raw
                                $configContent = $configContent -replace "DefaultBackupSource = '.*'", "DefaultBackupSource = '$($newPath -replace '\\','\\')'"
                                $configContent | Set-Content $ConfigPath -Encoding UTF8
                                $Config.DefaultBackupSource = $newPath
                                Write-Host "✓ Default source folder set to: $newPath" -ForegroundColor Green
                                Write-SysFlowLog -LogLevel "Info" -Message "Default backup source updated" -Details "New path: $newPath" -LogFilePath $Config.LogPath
                            } else {
                                Write-SysFlowLog -LogLevel "Warning" -Message "Default backup source change cancelled" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }

                        '4' {
                            Write-Host "\nCurrent default report path: $($Config.DefaultReportPath)" -ForegroundColor Cyan
                            $useGui = Read-Host "Use folder selection? (Y/N)"
                            
                            if ($useGui -match '^[Yy]$') {
                                $newPath = Get-FolderSelection "Select default report folder"
                            } else {
                                $newPath = Read-Host "Enter new default report folder"
                            }
                            
                            if ($newPath) {
                                $configContent = Get-Content $ConfigPath -Raw
                                $configContent = $configContent -replace "DefaultReportPath = '.*'", "DefaultReportPath = '$($newPath -replace '\\','\\')'"
                                $configContent | Set-Content $ConfigPath -Encoding UTF8
                                $Config.DefaultReportPath = $newPath
                                Write-Host "✓ Default report folder set to: $newPath" -ForegroundColor Green
                                Write-SysFlowLog -LogLevel "Info" -Message "Default report path updated" -Details "New path: $newPath" -LogFilePath $Config.LogPath
                            } else {
                                Write-SysFlowLog -LogLevel "Warning" -Message "Default report path change cancelled" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }

                        '5' {
                            Write-Host "\n=== Set Monitoring Thresholds ===" -ForegroundColor Cyan
                            Write-Host "Current values shown in parentheses" -ForegroundColor Gray
                            Write-Host ""
                            
                            $cpu = Read-Host "CPU threshold % (current: $($Config.CPUThreshold))"
                            $ram = Read-Host "RAM threshold % (current: $($Config.RAMThreshold))"
                            $storage = Read-Host "Storage threshold % (current: $($Config.StorageThreshold))"
                            $process = Read-Host "Process memory MB (current: $($Config.ProcessMemoryThreshold))"
                            
                            $configContent = Get-Content $ConfigPath -Raw
                            $changedThresholds = @()
                            
                            if ($cpu) { 
                                $configContent = $configContent -replace "CPUThreshold = \d+", "CPUThreshold = $cpu"
                                $Config.CPUThreshold = [int]$cpu
                                $changedThresholds += "CPU: $cpu%"
                            }
                            if ($ram) { 
                                $configContent = $configContent -replace "RAMThreshold = \d+", "RAMThreshold = $ram"
                                $Config.RAMThreshold = [int]$ram
                                $changedThresholds += "RAM: $ram%"
                            }
                            if ($storage) { 
                                $configContent = $configContent -replace "StorageThreshold = \d+", "StorageThreshold = $storage"
                                $Config.StorageThreshold = [int]$storage
                                $changedThresholds += "Storage: $storage%"
                            }
                            if ($process) { 
                                $configContent = $configContent -replace "ProcessMemoryThreshold = \d+", "ProcessMemoryThreshold = $process"
                                $Config.ProcessMemoryThreshold = [int]$process
                                $changedThresholds += "Process Memory: $process MB"
                            }
                            
                            if ($changedThresholds.Count -gt 0) {
                                $configContent | Set-Content $ConfigPath -Encoding UTF8
                                Write-Host "✓ Thresholds updated successfully" -ForegroundColor Green
                                Write-SysFlowLog -LogLevel "Info" -Message "Monitoring thresholds updated" -Details ($changedThresholds -join " | ") -LogFilePath $Config.LogPath
                            } else {
                                Write-SysFlowLog -LogLevel "Info" -Message "Monitoring thresholds not changed" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }

                        '6' {
                            $current = if ($Config.DefaultPackageManager) { $Config.DefaultPackageManager } else { 'winget' }
                            Write-Host "\nCurrent default package manager: $current" -ForegroundColor Cyan
                            $sel = Read-Host "Enter default manager (winget/choco)"
                            if ($sel -notin @('winget','choco')) {
                                Write-Host "Invalid choice. Please enter 'winget' or 'choco'." -ForegroundColor Yellow
                                Write-SysFlowLog -LogLevel "Warning" -Message "Invalid package manager selection attempted" -Details "Input: $sel" -LogFilePath $Config.LogPath
                            } else {
                                $configContent = Get-Content $ConfigPath -Raw
                                if ($configContent -match "DefaultPackageManager\s*=") {
                                    $configContent = $configContent -replace "DefaultPackageManager\s*=\s*'.*'", "DefaultPackageManager = '$sel'"
                                } else {
                                    if ($configContent -match "\}\s*$") {
                                        $configContent = $configContent -replace "\}\s*$", "    DefaultPackageManager = '$sel'`n}"
                                    } else {
                                        $configContent += "`nDefaultPackageManager = '$sel'"
                                    }
                                }
                                $configContent | Set-Content $ConfigPath -Encoding UTF8
                                $Config.DefaultPackageManager = $sel
                                Write-Host "✓ Default package manager set to: $sel" -ForegroundColor Green
                                Write-SysFlowLog -LogLevel "Info" -Message "Default package manager updated" -Details "New manager: $sel" -LogFilePath $Config.LogPath
                            }
                            Pause
                        }

                        'B' { $SettingsExit = $true }
                        'b' { $SettingsExit = $true }
                    }
                } until ($SettingsExit)
            }

            'Q' { 
                Write-SysFlowLog -LogLevel "Info" -Message "SysFlow application closed by user" -LogFilePath $Config.LogPath
                $MainExit = $true 
            }
            'q' { 
                Write-SysFlowLog -LogLevel "Info" -Message "SysFlow application closed by user" -LogFilePath $Config.LogPath
                $MainExit = $true 
            }
        }
    } until ($MainExit)
}

Write-SysFlowLog -LogLevel "Info" -Message "SysFlow applicatie gestart" -LogFilePath $Config.LogPath
Start-SysFlow




