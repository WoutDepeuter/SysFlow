. $PSScriptRoot\Get-StorageStats.ps1
Export-ModuleMember -Function Get-StorageStats
. $PSScriptRoot\Get-CPUStats.ps1
Export-ModuleMember -Function Get-CPUStats
. $PSScriptRoot\Get-RamStats.ps1
Export-ModuleMember -Function Get-RamStats

Get-StorageStats -Threshold 90