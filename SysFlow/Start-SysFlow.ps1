<#
.SYNOPSIS
    Start-SysFlow.ps1 - The central entry point for the application.
#>

# ------------------------------
# 1. INITIALIZATION & MODULES
# ------------------------------
# Ensure the script knows where the modules are located
$MonitorModulePath = Join-Path $PSScriptRoot 'Modules\MonitorModule\MonitorModule.psm1'

# Import the MonitorModule (if it exists)
if (Test-Path $MonitorModulePath) {
    Import-Module $MonitorModulePath -Force -ErrorAction Stop
} else {
    Write-Warning "Monitor module not found at: $MonitorModulePath"
}

# (You can import your BackupModule and SoftwareModule here later)


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

        # --- OPTION 2: BACKUP (Placeholder) ---
        '2' {
            Write-Host "Backup Module coming soon..." -ForegroundColor Gray
            Pause
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