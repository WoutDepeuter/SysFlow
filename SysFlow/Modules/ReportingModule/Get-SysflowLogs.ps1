function Get-SysFlowLogs {
    <#
    .SYNOPSIS
        Retrieves and parses the SysFlow log file into custom objects.
    .PARAMETER LogFilePath
        The path to the SysFlow.log file.
    .PARAMETER Tail
        Optional. The number of recent log entries to retrieve. Defaults to 50.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogFilePath,
        [int]$Tail = 50
    )

    if (-not (Test-Path $LogFilePath)) {
        return @() # Return empty array if no logs exist yet
    }

    # Regex to parse format: [2026-05-05 20:59:08] [Info] Message | Details: ...
    $regex = '^\[(?<Timestamp>.*?)\] \[(?<Level>.*?)\] (?<Message>.*?)(?: \| Details: (?<Details>.*))?$'
    
    $parsedLogs = @()
    # Read the last X lines to prevent the report from becoming too massive
    $rawLogs = Get-Content -Path $LogFilePath -Tail $Tail -ErrorAction SilentlyContinue

    foreach ($line in $rawLogs) {
        if ($line -match $regex) {
            $parsedLogs += [PSCustomObject]@{
                Timestamp = $matches['Timestamp']
                Level     = $matches['Level']
                Message   = $matches['Message']
                Details   = if ($matches['Details']) { $matches['Details'] } else { "-" }
            }
        }
    }

    # Return the logs in descending order (newest first)
    return $parsedLogs | Sort-Object Timestamp -Descending
}