#Function to show all menu options
Import-Module SysFlow.Modules.MonitorModule

function Show-Menu {
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "     Sysflow              " -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "1. System Status"
    Write-Host "2. Back Ups"
    Write-Host "3. Software Management"
    Write-Host "4. Taskmanager"
    Write-Host "5. Exit"
}

# Functie voor het nieuwe submenu
function Show-StatusMenu {
    Write-Host "----- System Status -----" -ForegroundColor Green
    Write-Host "1. CPU Only"
    Write-Host "2. RAM Only"
    Write-Host "3. Storage Only"
    Write-Host "4. Show All Stats"
    Write-Host "5. Back to Main Menu"
}

#clear the host and show the menu
Clear-Host
Show-Menu

#shows the menu until the users chooses to exit
do {
    $keuze = Read-Host "Select an option (1-5)"
    Clear-Host
    Write-Host "Je hebt gekozen voor optie: $keuze" -ForegroundColor Magenta
    Write-Host "---------------------------------"

    #switch to process the user's choice and open the correct module
    switch ($keuze) {
        '1' { 
            Write-Host "Module Loaded: System Status" -ForegroundColor Green 
            
            # --- NIEUW: SUBMENU LOOP ---
            do {
                Write-Host ""
                Show-StatusMenu
                $subKeuze = Read-Host "Select stat option (1-5)"
                Clear-Host
                
                # Toon wat er in het submenu gekozen is
                if ($subKeuze -ne '5') {
                    Write-Host "Status optie: $subKeuze" -ForegroundColor DarkCyan
                    Write-Host "-------------------"
                }

                switch ($subKeuze) {
                    '1' { 
                        Write-Host "Gathering CPU Stats..." -ForegroundColor Cyan
                        Get-CPUStats -threshold 70 | Format-Table -AutoSize
                    }
                    '2' { 
                        Write-Host "Gathering RAM Stats..." -ForegroundColor Cyan
                        Get-RamStats -threshold 70 | Format-Table -AutoSize
                    }
                    '3' { 
                        Write-Host "Gathering Storage Stats..." -ForegroundColor Cyan
                        Get-StorageStats -Threshold 80 | Format-Table -AutoSize
                    }
                    '4' { 
                        # Alles tonen
                        Write-Host "Gathering CPU Stats..." -ForegroundColor Cyan
                        Get-CPUStats -threshold 70 | Format-Table -AutoSize
                        Write-Host "Gathering RAM Stats..." -ForegroundColor Cyan
                        Get-RamStats -threshold 70 | Format-Table -AutoSize
                        Write-Host "Gathering Storage Stats..." -ForegroundColor Cyan
                        Get-StorageStats -Threshold 80 | Format-Table -AutoSize
                    }
                    '5' { Write-Host "Returning to Main Menu..." -ForegroundColor Yellow }
                    Default { Write-Host "Invalid Choice" -ForegroundColor Red }
                }
            } until ($subKeuze -eq '5')
            # --- EINDE SUBMENU LOOP ---
        }

        '2' { Write-Host "Module Loaded: Back Ups" -ForegroundColor Green }
        '3' { Write-Host "Module Loaded: Software Management" -ForegroundColor Green }
        '4' { Write-Host "Module Loaded: Taskmanager" -ForegroundColor Green }
        '5' { Write-Host "Closed sysflow" -ForegroundColor Yellow }
        Default { Write-Host "Invalid Choice" -ForegroundColor Red }
    }
    
    #if the user didn't choose to exit AND didn't just come from the submenu (optie 1), wait for input
    # Aangepast: Als je uit menu 1 komt, wil je direct het hoofdmenu zien, anders moet je 2x enteren.
    if ($keuze -ne '5' -and $keuze -ne '1') {
        Write-Host ""
        Write-Host "Press Enter to go back to the menu"
        Read-Host
        Clear-Host
        Show-Menu
    } elseif ($keuze -eq '1') {
        # Als we terugkomen van het submenu (1), maken we direct schoon en tonen we het hoofdmenu
        Clear-Host
        Show-Menu
    }

    #if the user chose to exit, the loop ends
} until ($keuze -eq '5')
#End of script