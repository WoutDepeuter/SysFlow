#function to update software using winget or chocolatey
function Update-Software {
    <#
    .SYNOPSIS
        Updates software via Winget or Chocolatey.
    .DESCRIPTION
        The Update-Software function updates a specified software package on the system.
        It supports updating via the Winget and Chocolatey package managers.
    .PARAMETER PackageName
        The name or ID of the package to update.
    .PARAMETER Manager
        Package manager to use for updating ('winget' or 'choco').
    .NOTES
    #>
    param(
        
        [string]$PackageName,
        [ValidateSet('winget', 'choco')]
        [string]$Manager = 'winget'

    
    )

    # Ensure Get-SoftwareList is available even if this script is dot-sourced directly
    if (-not (Get-Command -Name Get-SoftwareList -ErrorAction SilentlyContinue)) {
        try {
            $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
            $helperPath = Join-Path $scriptRoot 'Get-SoftwareList.ps1'
            if (Test-Path $helperPath) { . $helperPath } else { Write-Warning "Get-SoftwareList.ps1 not found at $helperPath" }
        } catch { Write-Warning "Failed to load Get-SoftwareList.ps1: $_" }
    }

    # If no package name provided, show interactive list
    if (-not $PackageName) {
        Write-Host "`n=== Installed Software ===" -ForegroundColor Cyan
        $software = Get-SoftwareList
        
        if ($software.Count -eq 0) {
            Write-Host "No software found." -ForegroundColor Yellow
            return----
        }

        # Display numbered list
        for ($i = 0; $i -lt $software.Count; $i++) {
            Write-Host "$($i + 1). $($software[$i].Name) (v$($software[$i].Version))" -ForegroundColor White
        }
        
        $choice = Read-Host "`nEnter number to update (or press Enter to cancel)"
        if (-not $choice -or -not [int]::TryParse($choice, [ref]0) -or [int]$choice -lt 1 -or [int]$choice -gt $software.Count) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
        
        $PackageName = $software[[int]$choice - 1].Name
        Write-Host "`nSelected: $PackageName" -ForegroundColor Green
    }

    # Auto-detect manager if not specified
    if (-not $Manager) {
        Write-Host "`nDetecting which manager installed '$PackageName'..." -ForegroundColor Yellow
        $detectedManager = Get-InstalledBy -PackageName $PackageName
        
        if ($detectedManager -ne 'unknown') {
            Write-Host "✓ Detected: $detectedManager" -ForegroundColor Green
            $Manager = $detectedManager
        } else {
            Write-Host "Could not auto-detect. Please specify manager." -ForegroundColor Yellow
            Write-Host "1. Winget"
            Write-Host "2. Chocolatey"
            $managerChoice = Read-Host "Select package manager (1 or 2)"
            $Manager = if ($managerChoice -eq '2') { 'choco' } else { 'winget' }
            Write-Host "Using: $Manager" -ForegroundColor Green
        }
    }

    try {
        
        #check what manager to use if manager is winget or choco uses that manager to update
        if ($Manager -eq 'winget') {
            Write-Host "Updating $PackageName using Winget..." -ForegroundColor Cyan
            winget upgrade --id $PackageName --silent --accept-source-agreements --accept-package-agreements
        }
        #check for check if manager is choco
        elseif ($Manager -eq 'choco') {
            Write-Host "Updating $PackageName using Chocolatey..." -ForegroundColor Cyan
            choco upgrade $PackageName -y
        }
        #output update command executed
        Write-Host "✓ Update command executed for $PackageName." -ForegroundColor Green
    }
    #error handling
    catch {
        Write-Error "Update failed: $_"
    }

}


# End of Update-Software function
