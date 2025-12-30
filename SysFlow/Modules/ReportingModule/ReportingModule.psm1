# ============================================================================
# ReportingModule.psm1
# Reporting Management Module - Generate and manage reports
# ============================================================================

# Get module root directory
$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================================
# Dot-source function files
# ============================================================================
. (Join-Path $moduleRoot 'Export-StatToCsv.ps1')
. (Join-Path $moduleRoot 'Write-SysFlowLog.ps1')

# ============================================================================
# Export public functions
# ============================================================================
Export-ModuleMember -Function 'Export-StatToCsv', 'Write-SysFlowLog'
