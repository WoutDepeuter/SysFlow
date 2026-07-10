#function to export statistics to CSV
function Export-StatToCsv {
    <#.SYNOPSIS
        Exports given statistics to a CSV file.
    .DESCRIPTION
        The Export-StatToCsv function takes a collection of statistics and exports them to a specified CSV file.
        It accepts parameters for the statistics data and the output file path.
    .PARAMETER Stats
        The collection of statistics to export.
    .PARAMETER OutputFilePath
        The path to the CSV file where the statistics will be saved.
    .EXAMPLE
        $stats = Get-CPUStats
        Export-StatToCsv -Stats $stats -OutputFilePath "C:\Reports\CPUStats.csv"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Stats,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFilePath
    )
    
    # Determine default log file path
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $sysflowRoot = Split-Path -Parent $moduleRoot
    $defaultLogPath = Join-Path $sysflowRoot "Logs\SysFlow.log"
    
    # Ensure Logs directory exists
    $logDir = Split-Path -Parent $defaultLogPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Log the export attempt
    Write-SysFlowLog -LogLevel 'Info' -Message "Exporting statistics to CSV" -Details "Output path: $OutputFilePath, Record count: $($Stats.Count)" -LogFilePath $defaultLogPath
    
    try {
        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputFilePath
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        # Normalize stats input to an array and abort if no records
        $Stats = @($Stats)

        # Attach a consistent run timestamp, date, and time to each record
        $runTimestamp = Get-Date
        $runDate = $runTimestamp.ToString('yyyy-MM-dd')
        $runTime = $runTimestamp.ToString('HH:mm:ss')
        $rows = $Stats | ForEach-Object {
            $item = $_
            if ($item -is [System.Collections.IDictionary]) { $item = [pscustomobject]$item }
            elseif ($item -isnot [System.Management.Automation.PSObject]) { $item = [pscustomobject]@{ Value = $item } }
            $item |
                Select-Object -ExcludeProperty RunDate, RunTime, RunTimestamp |
                Select-Object *,
                @{ Name = 'RunDate'; Expression = { $runDate } },
                @{ Name = 'RunTime'; Expression = { $runTime } },
                @{ Name = 'RunTimestamp'; Expression = { $runTimestamp } }
        }

        # Ensure $rows is always an array so .Count behaves as expected
        $rows = @($rows)

        if ($rows.Count -eq 0) {
            Write-Warning "No statistics provided to export. No file created: $OutputFilePath"
            Write-SysFlowLog -LogLevel 'Warning' -Message "No statistics to export" -Details "File: $OutputFilePath" -LogFilePath $defaultLogPath

            return [PSCustomObject]@{
                Timestamp   = Get-Date
                Action      = 'Export-StatToCsv'
                File        = $OutputFilePath
                Status      = 'NoData'
                Records     = 0
                Details     = 'No statistics provided to export.'
            }
        }

        $fileExists = Test-Path $OutputFilePath
        $exportParams = @{ Path = $OutputFilePath; NoTypeInformation = $true; Encoding = 'UTF8' }

        if ($fileExists) {
            $rows | Export-Csv @exportParams -Append -Force
        }
        else {
            $rows | Export-Csv @exportParams
        }

        Write-Output "Statistics exported successfully to $OutputFilePath"
        Write-SysFlowLog -LogLevel 'Info' -Message "Statistics exported successfully" -Details "File: $OutputFilePath; Records: $($rows.Count); Date: $runDate; Time: $runTime; Timestamp: $runTimestamp" -LogFilePath $defaultLogPath

        return [PSCustomObject]@{
            Timestamp   = Get-Date
            Action      = 'Export-StatToCsv'
            File        = $OutputFilePath
            Status      = 'Success'
            Records     = $rows.Count
            Details     = $null
        }
    }
    catch {
        Write-Error "Failed to export statistics: $_"
        Write-SysFlowLog -LogLevel 'Error' -Message "Failed to export statistics" -Details "Error: $_" -LogFilePath $defaultLogPath
    }
}


# End of Export-StatToCsv function
