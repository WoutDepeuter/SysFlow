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
    try {
        #check what manager to use if manager is winget or choco uses that manager to update
        if ($Manager -eq 'winget') {
            Write-Host "Updating $PackageName using Winget..."
            winget upgrade --id $PackageName --silent --accept-source-agreements --accept-package-agreements
        }
        #check for check if manager is choco
        elseif ($Manager -eq 'choco') {
            Write-Host "Updating $PackageName using Chocolatey..."
            choco upgrade $PackageName -y
        }
        #output update command executed
        Write-Host "Update command executed for $PackageName."
    }
    catch {
        Write-Error "Update failed: $_"
    }
}


# End of Update-Software function