# ============================================================================
# BackupModule.psm1
# Backup Management Module - Create, restore, and manage system backups
# ============================================================================

# Get module root directory
$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================================
# Dot-source function files
# ============================================================================

. (Join-Path $moduleRoot 'New-Backup.ps1')
. (Join-Path $moduleRoot 'Restore-Backup.ps1')
. (Join-Path $moduleRoot 'Remove-Backup.ps1')

# ============================================================================
# Export public functions
# ============================================================================

Export-ModuleMember -Function 'New-Backup', 'Restore-Backup', 'Remove-Backup'
