# ============================================================================
# MonitorModule.psm1
# System Monitoring Module - CPU, RAM, Storage, Uptime, and Process stats
# ============================================================================

# Get module root directory
$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================================
# Dot-source function files
# ============================================================================

. (Join-Path $moduleRoot 'Get-StorageStats.ps1')
. (Join-Path $moduleRoot 'Get-CPUStats.ps1')
. (Join-Path $moduleRoot 'Get-RamStats.ps1')
. (Join-Path $moduleRoot 'Get-Uptime.ps1')
. (Join-Path $moduleRoot 'Get-ProcessStats.ps1')

# ============================================================================
# Export public functions
# ============================================================================

Export-ModuleMember -Function 'Get-StorageStats', 'Get-CPUStats', 'Get-RamStats', 'Get-Uptime', 'Get-ProcessStats'
