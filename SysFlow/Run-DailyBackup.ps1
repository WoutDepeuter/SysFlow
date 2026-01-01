param(
    [string]$ConfigPathOverride
)

# Resolve script root and config path
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = if ($ConfigPathOverride) { $ConfigPathOverride } else { Join-Path $scriptRoot 'config.psd1' }

if (-not (Test-Path $configPath)) {
    Write-Error "Config file not found: $configPath"
    exit 1
}

# Load configuration
$Config = Import-PowerShellDataFile -Path $configPath

# Validate required settings
if (-not $Config.DefaultBackupSource -or -not $Config.DefaultBackupDestination) {
    Write-Error "DefaultBackupSource and DefaultBackupDestination must be set in config.psd1 for scheduled backups."
    exit 1
}

# Import unified SysFlow module
$modulePath = Join-Path $scriptRoot 'Modules\SysFlowModule.psm1'
if (-not (Test-Path $modulePath)) {
    Write-Error "SysFlowModule.psm1 not found at $modulePath"
    exit 1
}
Import-Module $modulePath -Force

# Build paths array (support single path or comma-separated list)
$pathsRaw = @($Config.DefaultBackupSource) -join ','
$paths = $pathsRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

# Optional: custom name prefix so you can see it's scheduled
$timestampName = "ScheduledBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"

try {
    Write-Host "Running scheduled backup..." -ForegroundColor Cyan
    $result = New-Backup -PathsToBackup $paths -BackupDestination $Config.DefaultBackupDestination -BackupName $timestampName

    # Log if logging is configured
    if ($Config.LogPath) {
        $details = "BackupPath=$($result.BackupPath); Size=$($result.Size)"
        Write-SysFlowLog -LogLevel 'Info' -Message 'Scheduled backup completed' -Details $details -LogFilePath $Config.LogPath
    }
}
catch {
    Write-Error "Scheduled backup failed: $_"
    if ($Config.LogPath) {
        Write-SysFlowLog -LogLevel 'Error' -Message 'Scheduled backup failed' -Details $_ -LogFilePath $Config.LogPath
    }
    exit 1
}