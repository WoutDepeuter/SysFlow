<#
.SYNOPSIS
    Registers a Windows Scheduled Task to run the SysFlow daily backup.

.DESCRIPTION
    Creates or updates a scheduled task that runs Run-DailyBackup.ps1
    every day at a specified time. It automatically chooses pwsh.exe
    when available, otherwise falls back to powershell.exe.

.PARAMETER TaskName
    Name of the scheduled task to create or update. Defaults to
    'SysFlow-DailyBackup'.

.PARAMETER Time
    Time of day in 24-hour HH:mm format at which the backup should run.
    Defaults to 03:00.

.PARAMETER UserId
    The user account under which the task runs. Defaults to the
    current user name.

.EXAMPLE
    .\Register-DailyBackupTask.ps1

    Registers a task named 'SysFlow-DailyBackup' to run daily at 03:00
    for the current user.

.EXAMPLE
    .\Register-DailyBackupTask.ps1 -TaskName 'SysFlow-Backup-22h' -Time '22:00'

    Registers a task that runs the daily backup every evening at 22:00.
#>
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