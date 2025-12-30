# SoftwareModule.psm1 - aggregate and export software management functions

$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path


# Dot-source function files
. (Join-Path $moduleRoot 'Get-SoftwareList.ps1')
. (Join-Path $moduleRoot 'Install-Software.ps1')
. (Join-Path $moduleRoot 'uninstall-Software.ps1')
. (Join-Path $moduleRoot 'update-Software.ps1')

# Export public functions
Export-ModuleMember -Function 'Get-SoftwareList','Install-Software','Uninstall-Software','Update-Software','Get-InstalledBy'
