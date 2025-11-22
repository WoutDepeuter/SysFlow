

function Show-Menu{
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "     Sysflow              " -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "1. System Status"
    Write-Host "2. Back Ups"
    Write-Host "3. Software Management"
    Write-Host "4. Taskmanager"
    Write-Host "5. Exit"    
}

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

Clear-Host
Show-Menu

do {
    $keuze = Read-Host "Select an option (1-5)"
    Clear-Host

    switch ($keuze) {
        '1' { Write-Host "Module Loaded: System Status" -ForegroundColor Green }
        '2' { Write-Host "Module Loaded: Back Ups" -ForegroundColor Green }
        '3' { Write-Host "Module Loaded: Software Management" -ForegroundColor Green }
        '4' { Write-Host "Module Loaded: Taskmanager" -ForegroundColor Green }
        '5' { Write-Host "Closed sysflow" -ForegroundColor Yellow }
        Default { Write-Host "Invalid Choice" -ForegroundColor Red }
    }

    if ($keuze -ne '5') {
        Write-Host ""
        Write-Host "Press Enter to go back to the menu"
        Read-Host
        Clear-Host
        Show-Menu
    }

} until ($keuze -eq '5')