# Function for the Status Submenu
function Show-StatusMenu {
    Write-Host "----- System Status -----" -ForegroundColor Green
    Write-Host "1. CPU Only"
    Write-Host "2. RAM Only"
    Write-Host "3. Storage Only"
    Write-Host "4. Show All Stats"
    Write-Host "5. System Uptime"
    Write-Host "6. Back to Main Menu"
}

# --- START SUBMENU LOOP ---
# Loop until the user chooses to exit
#submenu to show system stats
# Initialize variable
do {
    Write-Host ""
    Show-StatusMenu
    # Get user choice
    $subKeuze = Read-Host "Select stat option (1-6)"
    Clear-Host

    
    # Display the user's choice (unless they are exiting)
    if ($subKeuze -ne '6') {
        Write-Host "Status Option: $subKeuze" -ForegroundColor DarkCyan
        Write-Host "-------------------"
    }

    switch ($subKeuze) {
        '1' { 
            #show cpu stats
            
            Write-Host "Gathering CPU Stats..." -ForegroundColor Cyan
            Get-CPUStats -Threshold 70 | Format-Table -AutoSize
        }
        '2' { 
            #show ram stats
            Write-Host "Gathering RAM Stats..." -ForegroundColor Cyan
            Get-RamStats -Threshold 70 | Format-Table -AutoSize
        }
        '3' { #show storage stats
            Write-Host "Gathering Storage Stats..." -ForegroundColor Cyan
            Get-StorageStats -Threshold 80 | Format-Table -AutoSize 
        }
        '4' { 
            # Show All
            Write-Host "Gathering All Stats..." -ForegroundColor Cyan
            Get-CPUStats -Threshold 70 | Format-Table -AutoSize
            Get-RamStats -Threshold 70 | Format-Table -AutoSize
            Get-StorageStats -Threshold 80 | Format-Table -AutoSize
            Get-Uptime | Format-Table -AutoSize
        }
        #show uptime
        '5' { 
            Write-Host "Gathering Uptime..." -ForegroundColor Cyan
            Get-Uptime | Format-Table -AutoSize
        }
        #go back to main menu
        '6' 
        { 
            Write-Host "Returning to Main Menu..." -ForegroundColor Yellow 
        }
        #invalid choice
        Default { 
            Write-Host "Invalid Choice" -ForegroundColor Red 
        }
    }
} until ($subKeuze -eq '6')
# --- END SUBMENU LOOP ---

