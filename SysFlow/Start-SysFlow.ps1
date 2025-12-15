<#
.SYNOPSIS
    Start-SysFlow.ps1 - The central entry point for the application.
#>
function Get-FolderSelection {
    param([string]$Description)
    
    # Load Windows Forms assembly
    Add-Type -AssemblyName System.Windows.Forms
    
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.ShowNewFolderButton = $true
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}
# ------------------------------
# 1. INITIALIZATION & MODULES
# ------------------------------
# Ensure the script knows where the modules are located
$MonitorModulePath = Join-Path $PSScriptRoot 'Modules\MonitorModule\MonitorModule.psm1'
$BackupModulePath  = Join-Path $PSScriptRoot 'Modules\BackupModule\BackupModule.psm1'

# Import the MonitorModule (if it exists)
if (Test-Path $MonitorModulePath) {
    Import-Module $MonitorModulePath -Force -ErrorAction Stop
} else {
    Write-Warning "Monitor module not found at: $MonitorModulePath"
}

# Import the BackupModule (if it exists)
if (Test-Path $BackupModulePath) {
    Import-Module $BackupModulePath -Force -ErrorAction Stop
} else {
    Write-Warning "Backup module not found at: $BackupModulePath"
}


# ------------------------------
# 2. MENU FUNCTIONS
# ------------------------------

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

function Show-StatusMenu {
    Write-Host "----- System Status Submenu -----" -ForegroundColor Green
    Write-Host "1. CPU Only"
    Write-Host "2. RAM Only"
    Write-Host "3. Storage Only"
    Write-Host "4. Show All Stats"
    Write-Host "5. System Uptime"
    Write-Host "6. Process Stats"
    Write-Host "B. Back to Main Menu" # 'B' is often more intuitive than '7' for 'Back'
}

function Show-BackupMenu {
    Write-Host "----- Backup Management Submenu -----" -ForegroundColor Green
    Write-Host "1. Create Backup"
    Write-Host "2. Restore Backup"
    Write-Host "3. Remove Backup(s)"
    Write-Host "4. List Backups"
    Write-Host "B. Back to Main Menu"
}


# ------------------------------
# 3. MAIN LOOP (MAIN MENU)
# ------------------------------

$MainExit = $false

do {
    # Show the main menu
    Show-MainMenu
    $MainChoice = Read-Host "Make a selection"

    switch ($MainChoice) {
        
        # --- OPTION 1: MONITORING (This is your original script) ---
        '1' {
            $SubExit = $false
            do {
                Write-Host ""
                Show-StatusMenu
                $SubChoice = Read-Host "Select stat option"
                Clear-Host

                switch ($SubChoice) {
                    
                    '1' { Write-Host "Gathering CPU Stats..." -ForegroundColor Cyan; Get-CPUStats -Threshold 70 | Format-Table -AutoSize }
                    '2' { Write-Host "Gathering RAM Stats..." -ForegroundColor Cyan; Get-RamStats -Threshold 70 | Format-Table -AutoSize }
                    '3' { Write-Host "Gathering Storage Stats..." -ForegroundColor Cyan; Get-StorageStats -Threshold 80 | Format-Table -AutoSize }
                    '4' { 
                        Write-Host "Gathering All Stats..." -ForegroundColor Cyan
                        Get-CPUStats -Threshold 70 | Format-Table -AutoSize
                        Get-RamStats -Threshold 70 | Format-Table -AutoSize
                        Get-StorageStats -Threshold 80 | Format-Table -AutoSize
                        Get-Uptime | Format-Table -AutoSize
                    }
                    '5' { Write-Host "Gathering Uptime..." -ForegroundColor Cyan; Get-Uptime | Format-Table -AutoSize }
                    '6' { Write-Host "Gathering Process Stats..." -ForegroundColor Cyan; Get-ProcessStats -threshold 500 | Format-Table -AutoSize }
                    
                    # Back to Main Menu
                    'B' { 
                        Write-Host "Returning to Main Menu..." -ForegroundColor Yellow
                        $SubExit = $true 
                    }
                    'b' { 
                        Write-Host "Returning to Main Menu..." -ForegroundColor Yellow
                        $SubExit = $true 
                    }
                    
                    Default { Write-Host "Invalid choice in submenu" -ForegroundColor Red }
                }
            } until ($SubExit -eq $true)
        }

        # --- OPTION 2: BACKUP SUBMENU ---
        '2' {
            $BackupExit = $false
            do {
                Write-Host ""
                Show-BackupMenu
                $BackupChoice = Read-Host "Select backup option"
                Clear-Host

                switch ($BackupChoice) {
                    '1' {
    Write-Host "Create a new backup" -ForegroundColor Cyan
    
    # --- CHANGE START ---
    $useGui = Read-Host "Do you want to select folders using a window? (Y/N)"
    
    if ($useGui -eq 'Y' -or $useGui -eq 'y') {
        # Select Source
        Write-Host "Select the folder you want to backup..." -ForegroundColor Yellow
        $sourcePath = Get-FolderSelection -Description "Select folder to Backup"
        
        # Select Destination
        if ($sourcePath) {
            Write-Host "Select where to save the backup..." -ForegroundColor Yellow
            $destPath = Get-FolderSelection -Description "Select Destination for Backup"
        }
        
        # Assign to the variables your script uses
        if ($sourcePath) { $pathsInput = $sourcePath }
        if ($destPath)   { $dest = $destPath }
        
    } else {
        # Fallback to original manual typing
        $pathsInput = Read-Host "Enter path(s) to backup (comma-separated)"
        $dest = Read-Host "Enter backup destination folder"
    }
    # --- CHANGE END ---

    # ... rest of your existing logic ...
    $name = Read-Host "Optional: Enter backup name (press Enter for default)"
    # ...
}
                    '2' {
                        Write-Host "Restore a backup" -ForegroundColor Cyan
                        $file = Read-Host "Enter full path to backup .zip file"
                        $restoreTo = Read-Host "Enter restore destination folder"
                        if (-not $file -or -not $restoreTo) {
                            Write-Host "Backup file and destination are required." -ForegroundColor Red
                            break
                        }
                        Restore-Backup -BackupFilePath $file -RestoreDestination $restoreTo | Format-List
                    }
                    '3' {
                        Write-Host "Remove backup(s)" -ForegroundColor Cyan
                        $dest = Read-Host "Enter backup destination folder to manage"
                        if (-not $dest) { Write-Host "Destination is required." -ForegroundColor Red; break }
                        Remove-Backup -BackupDestination $dest
                    }
                    '4' {
                        Write-Host "List backups" -ForegroundColor Cyan
                        $dest = Read-Host "Enter backup destination folder to list"
                        if (-not $dest) { Write-Host "Destination is required." -ForegroundColor Red; break }
                        $list = Remove-Backup -BackupDestination $dest -ListOnly
                        if ($list) { $list | Select-Object Index,Name,Size,Created | Format-Table -AutoSize }
                    }
                    'B' { Write-Host "Returning to Main Menu..." -ForegroundColor Yellow; $BackupExit = $true }
                    'b' { Write-Host "Returning to Main Menu..." -ForegroundColor Yellow; $BackupExit = $true }
                    Default { Write-Host "Invalid choice in backup submenu" -ForegroundColor Red }
                }
            } until ($BackupExit -eq $true)
        }

        # --- OPTION 3: SOFTWARE (Placeholder) ---
        '3' {
            Write-Host "Software Module coming soon..." -ForegroundColor Gray
            Pause
        }

        # --- OPTION Q: EXIT ---
        'Q' { 
            Write-Host "Exiting SysFlow. Goodbye!" -ForegroundColor Magenta
            $MainExit = $true 
        }
        'q' { 
            Write-Host "Exiting SysFlow. Goodbye!" -ForegroundColor Magenta
            $MainExit = $true 
        }

        Default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red 
            Start-Sleep -Seconds 1
        }
    }

} until ($MainExit -eq $true)
# End of Start-SysFlow.ps1
