#function to check which manager installed a package
function Get-InstalledBy {
    <#
    .SYNOPSIS
        Determines which package manager installed a given software.
    
    .PARAMETER PackageName
        The name of the software to check.
    
    .OUTPUTS
        Returns 'winget', 'choco', or 'unknown'.
    #>
    param([string]$PackageName)
    
    try {
        # Check Winget
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $wingetList = winget list --name $PackageName 2>$null
            if ($wingetList -match $PackageName) {
                return 'winget'
            }
        }
        
        # Check Chocolatey
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $chocoList = choco list $PackageName 2>$null
            if ($chocoList -match $PackageName) {
                return 'choco'
            }
        }
    }
    catch { }
    
    return 'unknown'
}

#function to uninstall software
function Uninstall-Software {
    <#
    .SYNOPSIS
        Uninstalls software via Winget or Chocolatey with auto-detection.
    .DESCRIPTION
        The Uninstall-Software function removes a specified software package from the system.
        It supports uninstallation via the Winget and Chocolatey package managers.
        If no Manager is specified, it attempts to auto-detect which manager installed the software.
    .PARAMETER PackageName
        The name or ID of the package to uninstall.
    .PARAMETER Manager
        Package manager to use for uninstallation ('winget' or 'choco').
        If omitted, the function attempts to auto-detect.
    .NOTES
#>


#parameters for the function
    param(
        [string]$PackageName,
        [ValidateSet('winget', 'choco')]
        [string]$Manager
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
            return
        }

        # Display numbered list
        for ($i = 0; $i -lt $software.Count; $i++) {
            Write-Host "$($i + 1). $($software[$i].Name) (v$($software[$i].Version))" -ForegroundColor White
        }
        
        $choice = Read-Host "`nEnter number to uninstall (or press Enter to cancel)"
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
        #check what manager to use if manager is winget or choco uses that manager to uninstall
        if ($Manager -eq 'winget') {
            Write-Host "Uninstalling $PackageName using Winget..." -ForegroundColor Cyan
            winget uninstall --id $PackageName --silent --accept-source-agreements --accept-package-agreements
        }
        #check for check if manager is choco
        elseif ($Manager -eq 'choco') {
            Write-Host "Uninstalling $PackageName using Chocolatey..." -ForegroundColor Cyan
            choco uninstall $PackageName -y
        }
        Write-Host "✓ Uninstallation command executed for $PackageName." -ForegroundColor Green
        Write-Host "Uninstallation command executed for $PackageName."
    }
    #error handling
    catch {
        
        Write-Error "Uninstallation failed: $_"
    }

    return [PSCustomObject]@{
        Timestamp   = Get-Date
        Action      = "Uninstall-Software"
        PackageName = $PackageName
        Manager     = $Manager
        Status      = $status
        Details     = $errorDetails
    }

    
    
}
# End of Uninstall-Software function

