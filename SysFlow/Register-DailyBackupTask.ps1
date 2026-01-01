param(
    [string]$TaskName = 'SysFlow-DailyBackup',
    [string]$Time = '03:00',          # HH:mm, 24h format
    [string]$UserId = $env:USERNAME   # default to current user
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupScript = Join-Path $scriptRoot 'Run-DailyBackup.ps1'

if (-not (Test-Path $backupScript)) {
    Write-Error "Run-DailyBackup.ps1 not found at $backupScript"
    exit 1
}

# Parse time
if (-not ([DateTime]::TryParse($Time, [ref]([DateTime]::MinValue)))) {
    Write-Error "Invalid time format '$Time'. Use HH:mm (24-hour)."
    exit 1
}

$trigger = New-ScheduledTaskTrigger -Daily -At $Time

# Use pwsh.exe if available, otherwise powershell.exe
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    $exe = $pwsh.Source
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$backupScript`""
} else {
    $exe = (Get-Command powershell.exe).Source
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$backupScript`""
}

$action = New-ScheduledTaskAction -Execute $exe -Argument $args

Write-Host "Registering scheduled task '$TaskName' to run daily at $Time..." -ForegroundColor Cyan

try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -User $UserId -RunLevel Highest -Force | Out-Null
    Write-Host "✓ Scheduled task '$TaskName' registered successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to register scheduled task: $_"
    exit 1
}