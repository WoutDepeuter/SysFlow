#function to uninstall software
function Uninstall-Software {
    <#
    .SYNOPSIS
        Uninstalls software via Winget or Chocolatey.
    .DESCRIPTION
        The Uninstall-Software function removes a specified software package from the system.
        It supports uninstallation via the Winget and Chocolatey package managers.
    .PARAMETER PackageName
        The name or ID of the package to uninstall.
    .PARAMETER Manager
        Package manager to use for uninstallation ('winget' or 'choco').
    .NOTES
#>

    param(
        [string]$PackageName,
        [ValidateSet('winget', 'choco')]
        [string]$Manager = 'winget'
    )

    try {
        #check what manager to use if manager is winget or choco uses that manager to uninstall
        if ($Manager -eq 'winget') {
            Write-Host "Uninstalling $PackageName using Winget..."
            winget uninstall --id $PackageName --silent --accept-source-agreements --accept-package-agreements
        }
        #check for check if manager is choco
        elseif ($Manager -eq 'choco') {
            Write-Host "Uninstalling $PackageName using Chocolatey..."
            choco uninstall $PackageName -y
        }
        Write-Host "Uninstallation command executed for $PackageName."
    }
    catch {
        Write-Error "Uninstallation failed: $_"
    }

}
# End of Uninstall-Software function
