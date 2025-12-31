#function to export statistics to HTML
function Export-StatToHtml {
    <#.SYNOPSIS
        Exports statistics to an HTML report with timestamps (appends to existing file).
    .DESCRIPTION
        Takes a collection of statistics, adds run date/time/timestamp columns, and appends to an HTML file.
        If the file doesn't exist, creates a new one. If it exists, appends new rows to the existing table.
        Creates the output directory if needed and logs success or errors using Write-SysFlowLog.
    .PARAMETER Stats
        Collection of objects to render as a table.
    .PARAMETER OutputFilePath
        Target HTML file path.
    .PARAMETER Title
        Optional page title/header. Defaults to "SysFlow Report".
    .EXAMPLE
        Export-StatToHtml -Stats $stats -OutputFilePath "C:\Reports\CPU.html" -Title "CPU Stats"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Stats,

        [Parameter(Mandatory=$true)]
        [string]$OutputFilePath,

        [string]$Title = 'SysFlow Report'
    )

    # Determine default log file path
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $sysflowRoot = Split-Path -Parent $moduleRoot
    $defaultLogPath = Join-Path $sysflowRoot 'Logs\SysFlow.log'

    # Ensure Logs directory exists
    $logDir = Split-Path -Parent $defaultLogPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Write-SysFlowLog -LogLevel 'Info' -Message 'Exporting statistics to HTML' -Details "Output path: $OutputFilePath; Records: $($Stats.Count)" -LogFilePath $defaultLogPath

    try {
        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputFilePath
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Attach run date/time/timestamp
        $runTimestamp = Get-Date
        $runDate = $runTimestamp.ToString('yyyy-MM-dd')
        $runTime = $runTimestamp.ToString('HH:mm:ss')
        $rows = $Stats | ForEach-Object {
            $item = $_
            if ($item -is [System.Collections.IDictionary]) { $item = [pscustomobject]$item }
            elseif ($item -isnot [System.Management.Automation.PSObject]) { $item = [pscustomobject]@{ Value = $item } }
            $item | Select-Object *,
                @{ Name = 'RunDate'; Expression = { $runDate } },
                @{ Name = 'RunTime'; Expression = { $runTime } },
                @{ Name = 'RunTimestamp'; Expression = { $runTimestamp } }
        }

        # Check if file exists
        if (Test-Path $OutputFilePath) {
            # File exists - append new rows to existing table
            $existingContent = Get-Content -Path $OutputFilePath -Raw
            
            # Generate only the table rows (tr elements) for new data
            $tempHtml = $rows | ConvertTo-Html -Fragment
            # Extract just the data rows (skip the header row)
            $tempLines = $tempHtml -split "`n"
            $dataRows = $tempLines | Where-Object { $_ -match '<tr><td>' }
            $newRowsHtml = $dataRows -join "`n"
            
            # Insert new rows before the closing </table> tag
            $updatedContent = $existingContent -replace '</table>', "$newRowsHtml`n</table>"
            $updatedContent | Set-Content -Path $OutputFilePath -Encoding UTF8
            
            Write-SysFlowLog -LogLevel 'Info' -Message 'Statistics appended to existing HTML' -Details "File: $OutputFilePath; New records: $($rows.Count); Date: $runDate; Time: $runTime" -LogFilePath $defaultLogPath
        }
        else {
            # File doesn't exist - create new HTML file
            $style = @"
<style>
    body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; color: #1f2937; background: #f9fafb; }
    h1 { color: #111827; font-size: 20px; margin-bottom: 4px; }
    .meta { color: #4b5563; margin-bottom: 12px; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; background: #ffffff; }
    th, td { border: 1px solid #e5e7eb; padding: 8px 10px; text-align: left; font-size: 13px; }
    th { background: #f3f4f6; font-weight: 600; }
    tr:nth-child(even) { background: #f9fafb; }
</style>
"@

            $meta = "Generated: $runDate $runTime"
            $htmlTable = $rows | ConvertTo-Html -Fragment
            $content = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>$Title</title>
$style
</head>
<body>
<h1>$Title</h1>
<div class="meta">$meta</div>
$htmlTable
</body>
</html>
"@

            $content | Set-Content -Path $OutputFilePath -Encoding UTF8
            Write-SysFlowLog -LogLevel 'Info' -Message 'Statistics exported to new HTML' -Details "File: $OutputFilePath; Records: $($rows.Count); Date: $runDate; Time: $runTime" -LogFilePath $defaultLogPath
        }
    }
    catch {
        Write-Error "Failed to export statistics to HTML: $_"
        Write-SysFlowLog -LogLevel 'Error' -Message 'Failed to export statistics to HTML' -Details "Error: $_" -LogFilePath $defaultLogPath
    }
}

# End of Export-StatToHtml function
