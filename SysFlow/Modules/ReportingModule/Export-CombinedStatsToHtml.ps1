#function to export combined statistics to a single HTML report
function Export-CombinedStatsToHtml {
    <#.SYNOPSIS
        Exports multiple stat collections to a single HTML report with sections.
    .DESCRIPTION
        Takes multiple collections of statistics and combines them into one HTML file
        with separate sections and tables for each stat type.
    .PARAMETER CpuStats
        CPU statistics collection.
    .PARAMETER RamStats
        RAM statistics collection.
    .PARAMETER StorageStats
        Storage statistics collection.
    .PARAMETER ProcessStats
        Process statistics collection.
    .PARAMETER UptimeStats
        Uptime statistics collection.
    .PARAMETER OutputFilePath
        Target HTML file path.
    .PARAMETER Title
        Optional page title. Defaults to "SysFlow System Report".
    .EXAMPLE
        Export-CombinedStatsToHtml -CpuStats $cpu -RamStats $ram -StorageStats $storage -OutputFilePath "C:\Reports\System.html"
    #>
    param(
        [array]$CpuStats,
        [array]$RamStats,
        [array]$StorageStats,
        [array]$ProcessStats,
        [array]$UptimeStats,

        [Parameter(Mandatory=$true)]
        [string]$OutputFilePath,

        [string]$Title = 'SysFlow System Report'
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

    Write-SysFlowLog -LogLevel 'Info' -Message 'Exporting combined statistics to HTML' -Details "Output path: $OutputFilePath" -LogFilePath $defaultLogPath

    try {
        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputFilePath
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Get run timestamp
        $runTimestamp = Get-Date
        $runDate = $runTimestamp.ToString('yyyy-MM-dd')
        $runTime = $runTimestamp.ToString('HH:mm:ss')

        # Helper function to add timestamp columns
        function Add-Timestamps {
            param([array]$Stats)
            if (-not $Stats) { return @() }
            $Stats | ForEach-Object {
                $item = $_
                if ($item -is [System.Collections.IDictionary]) { $item = [pscustomobject]$item }
                elseif ($item -isnot [System.Management.Automation.PSObject]) { $item = [pscustomobject]@{ Value = $item } }
                $item | Select-Object *,
                    @{ Name = 'RunDate'; Expression = { $runDate } },
                    @{ Name = 'RunTime'; Expression = { $runTime } },
                    @{ Name = 'RunTimestamp'; Expression = { $runTimestamp } }
            }
        }

        $style = @"
<style>
    body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; color: #1f2937; background: #f9fafb; }
    h1 { color: #111827; font-size: 24px; margin-bottom: 8px; }
    h2 { color: #374151; font-size: 18px; margin-top: 32px; margin-bottom: 12px; border-bottom: 2px solid #e5e7eb; padding-bottom: 4px; }
    .meta { color: #4b5563; margin-bottom: 24px; font-size: 13px; }
    table { border-collapse: collapse; width: 100%; background: #ffffff; margin-bottom: 24px; }
    th, td { border: 1px solid #e5e7eb; padding: 8px 10px; text-align: left; font-size: 13px; }
    th { background: #f3f4f6; font-weight: 600; }
    tr:nth-child(even) { background: #f9fafb; }
    .section { margin-bottom: 32px; }
</style>
"@

        $meta = "Generated: $runDate $runTime"
        $sections = ""

        # CPU Section
        if ($CpuStats) {
            $cpuRows = Add-Timestamps -Stats $CpuStats
            $cpuTable = $cpuRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>CPU Statistics</h2>$cpuTable</div>"
        }

        # RAM Section
        if ($RamStats) {
            $ramRows = Add-Timestamps -Stats $RamStats
            $ramTable = $ramRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>RAM Statistics</h2>$ramTable</div>"
        }

        # Storage Section
        if ($StorageStats) {
            $storageRows = Add-Timestamps -Stats $StorageStats
            $storageTable = $storageRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>Storage Statistics</h2>$storageTable</div>"
        }

        # Uptime Section
        if ($UptimeStats) {
            $uptimeRows = Add-Timestamps -Stats $UptimeStats
            $uptimeTable = $uptimeRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>System Uptime</h2>$uptimeTable</div>"
        }

        # Process Section (limited to top entries for readability)
        if ($ProcessStats) {
            $processRows = Add-Timestamps -Stats $ProcessStats
            $processTable = $processRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>Process Statistics</h2>$processTable</div>"
        }
        

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
$sections
</body>
</html>
"@

        $content | Set-Content -Path $OutputFilePath -Encoding UTF8
        Write-SysFlowLog -LogLevel 'Info' -Message 'Combined statistics exported to HTML' -Details "File: $OutputFilePath; Date: $runDate; Time: $runTime" -LogFilePath $defaultLogPath
    }
    catch {
        Write-Error "Failed to export combined statistics to HTML: $_"
        Write-SysFlowLog -LogLevel 'Error' -Message 'Failed to export combined statistics to HTML' -Details "Error: $_" -LogFilePath $defaultLogPath
    }
}

# End of Export-CombinedStatsToHtml function
