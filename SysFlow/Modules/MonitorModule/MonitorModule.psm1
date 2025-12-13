. $PSScriptRoot\Get-StorageStats.ps1
Export-ModuleMember -Function Get-StorageStats
. $PSScriptRoot\Get-CPUStats.ps1
Export-ModuleMember -Function Get-CPUStats
. $PSScriptRoot\Get-RamStats.ps1
Export-ModuleMember -Function Get-RamStats

. $PSScriptRoot\Get-Uptime.ps1
Export-ModuleMember -Function Get-Uptime

. $PSScriptRoot\Get-ProcessStats.ps1
Export-ModuleMember -Function Get-ProcessStats
# Export the functions that you want to be available to the user.
Export-ModuleMember -Function Get-StorageStats, Get-CPUStats, Get-RamStats
