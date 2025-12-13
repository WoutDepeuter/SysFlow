
function Get-ProcessStats {
    <#
    .SYNOPSIS
        Retrieves process statistics and alerts on high memory usage.

    .DESCRIPTION
        The Get-ProcessStats function gathers information about running processes including name,
        process ID, owner, and memory usage in MB. It alerts when processes exceed the specified
        memory threshold.

    .PARAMETER threshold
        Memory usage threshold in MB for triggering an alert.
        Default value is 80. Processes using more memory will trigger a warning.

    .EXAMPLE
        Get-ProcessStats
        
        Retrieves all processes with default threshold of 80 MB.

    .EXAMPLE
        Get-ProcessStats -threshold 500
        
        Retrieves processes and alerts if any use more than 500 MB.

    .OUTPUTS
        PSCustomObject array with properties:
        - Name: Process name
        - ProcessId: Process ID
        - Owner: Process owner/user
        - MemoryUsageMB: Memory usage in MB

    .NOTES
        Author: SysFlow
        Version: 1.0
        Requires: PowerShell with CIM access
    #>
    [CmdletBinding()]
    param(
        [int]$threshold = 80
    )

    # Get process information
    $processes = Get-CimInstance -ClassName Win32_Process | Select-Object Name, ProcessId, @{Name="Owner";Expression={($_.GetOwner().User)}}, @{Name="MemoryUsageMB";Expression={[math]::Round($_.WorkingSetSize / 1MB, 2)}}

    # Filter processes exceeding memory usage threshold
    $highMemoryProcesses = $processes | Where-Object { $_.MemoryUsageMB -ge $threshold }

    if ($highMemoryProcesses) {
        Write-Host "ALERT: The following processes are using more than $threshold MB of memory:" -ForegroundColor Red
        $highMemoryProcesses | Format-Table -AutoSize
    } else {
        Write-Host "All processes are within acceptable memory usage limits." -ForegroundColor Green
    }

    return $processes
}