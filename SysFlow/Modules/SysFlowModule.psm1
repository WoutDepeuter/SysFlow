# ============================================================================
# SysFlowModule.psm1
# Unified SysFlow module aggregating all submodules
# ============================================================================

# Get root paths
$moduleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$sysflowRoot = Split-Path -Parent $moduleRoot

# ============================================================================
# Dot-source Backup functions
# ============================================================================
$backupRoot = Join-Path $moduleRoot 'BackupModule'
if (Test-Path $backupRoot) {
    . (Join-Path $backupRoot 'New-Backup.ps1')
    . (Join-Path $backupRoot 'Restore-Backup.ps1')
    . (Join-Path $backupRoot 'Remove-Backup.ps1')
}

# ============================================================================
# Dot-source Monitor functions
# ============================================================================
$monitorRoot = Join-Path $moduleRoot 'MonitorModule'
if (Test-Path $monitorRoot) {
    . (Join-Path $monitorRoot 'Get-StorageStats.ps1')
    . (Join-Path $monitorRoot 'Get-CPUStats.ps1')
    . (Join-Path $monitorRoot 'Get-RamStats.ps1')
    . (Join-Path $monitorRoot 'Get-Uptime.ps1')
    . (Join-Path $monitorRoot 'Get-ProcessStats.ps1')
}

# ============================================================================
# Dot-source Reporting functions
# ============================================================================
$reportingRoot = Join-Path $moduleRoot 'ReportingModule'
if (Test-Path $reportingRoot) {
    . (Join-Path $reportingRoot 'Write-SysFlowLog.ps1')
    . (Join-Path $reportingRoot 'Export-StatToCsv.ps1')
    . (Join-Path $reportingRoot 'Export-StatToHtml.ps1')
    . (Join-Path $reportingRoot 'Export-CombinedStatsToHtml.ps1')
    . (Join-Path $reportingRoot 'Export-UnifiedStatsToHtml.ps1')
}

# ============================================================================
# Dot-source Software functions
# ============================================================================
$softwareRoot = Join-Path $moduleRoot 'SoftwareModule'
if (Test-Path $softwareRoot) {
    . (Join-Path $softwareRoot 'Get-SoftwareList.ps1')
    . (Join-Path $softwareRoot 'Install-Software.ps1')
    . (Join-Path $softwareRoot 'uninstall-Software.ps1')
    . (Join-Path $softwareRoot 'update-Software.ps1')
}

# ============================================================================
# Export all public functions from all feature areas
# ============================================================================
Export-ModuleMember -Function 'New-Backup','Restore-Backup','Remove-Backup','Get-StorageStats','Get-CPUStats','Get-RamStats','Get-Uptime','Get-ProcessStats','Write-SysFlowLog','Export-StatToCsv','Export-StatToHtml','Export-CombinedStatsToHtml','Export-UnifiedStatsToHtml','Get-SoftwareList','Install-Software','Uninstall-Software','Update-Software','Get-InstalledBy'