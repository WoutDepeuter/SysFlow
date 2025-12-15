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
                            $dest = Read-Host "Enter backup destination folder"
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
                        $dest = Read-Host "Enter backup destination folder"
                        Remove-Backup -BackupDestination $dest
                    }

                    '4' {
                        $dest = Read-Host "Enter backup destination folder"
                        Remove-Backup -BackupDestination $dest -ListOnly |
                            Format-Table Index, Name, Size, Created -AutoSize
                    }

                    'B' { $BackupExit = $true }
                    'b' { $BackupExit = $true }
                }
            } until ($BackupExit)
        }

        '3' {
            Write-Host "Software Module coming soon..." -ForegroundColor Gray
            Pause
        }

        'Q' { $MainExit = $true }
        'q' { $MainExit = $true }
    }
} until ($MainExit)
