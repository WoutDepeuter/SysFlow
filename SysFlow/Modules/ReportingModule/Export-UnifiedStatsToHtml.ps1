# Function to export statistics to a unified HTML file with sections
function Export-UnifiedStatsToHtml {
    <#.SYNOPSIS
        Exports statistics to a unified HTML report with labeled sections (appends to existing file).
    .DESCRIPTION
        Takes multiple statistics collections with labels, adds run date/time/timestamp columns, 
        and appends to a single HTML file with section headers.
        If the file doesn't exist, creates a new one. If it exists, appends new sections.
    .PARAMETER StatsHashtable
        Hashtable where keys are section titles and values are stat collections.
    .PARAMETER OutputFilePath
        Target HTML file path.
    .PARAMETER PageTitle
        Optional page title. Defaults to "SysFlow Report".
    .EXAMPLE
        $stats = @{
            'CPU Stats' = $cpuStats
            'RAM Stats' = $ramStats
        }
        Export-UnifiedStatsToHtml -StatsHashtable $stats -OutputFilePath "C:\Reports\Report.html"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StatsHashtable,

        [Parameter(Mandatory=$true)]
        [string]$OutputFilePath,

        [string]$PageTitle = 'SysFlow Report'
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

    Write-SysFlowLog -LogLevel 'Info' -Message 'Exporting statistics to unified HTML' -Details "Output path: $OutputFilePath; Sections: $($StatsHashtable.Count)" -LogFilePath $defaultLogPath

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

        # Build sections HTML
        $sectionsHtml = @()
        foreach ($sectionTitle in $StatsHashtable.Keys) {
            $stats = $StatsHashtable[$sectionTitle]
            
            if ($null -eq $stats -or $stats.Count -eq 0) { continue }

            $rows = $stats | ForEach-Object {
                $item = $_
                if ($item -is [System.Collections.IDictionary]) { $item = [pscustomobject]$item }
                elseif ($item -isnot [System.Management.Automation.PSObject]) { $item = [pscustomobject]@{ Value = $item } }
                $item | Select-Object *,
                    @{ Name = 'RunDate'; Expression = { $runDate } },
                    @{ Name = 'RunTime'; Expression = { $runTime } },
                    @{ Name = 'RunTimestamp'; Expression = { $runTimestamp } }
            }

            $htmlTable = $rows | ConvertTo-Html -Fragment
            $sectionHtml = @"
<h2>$sectionTitle</h2>
<div class="section">
$htmlTable
</div>
"@
            $sectionsHtml += $sectionHtml
        }

        $style = @"
<style>
    body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; color: #1f2937; background: #f9fafb; }
    h1 { color: #111827; font-size: 24px; margin-bottom: 8px; margin-top: 0; }
    h2 { color: #374151; font-size: 16px; margin-top: 24px; margin-bottom: 8px; border-bottom: 2px solid #e5e7eb; padding-bottom: 4px; }
    .meta { color: #6b7280; margin-bottom: 20px; font-size: 12px; background: #f3f4f6; padding: 8px 12px; border-radius: 4px; }
    .section { margin-bottom: 16px; }
    table { border-collapse: collapse; width: 100%; background: #ffffff; border: 1px solid #e5e7eb; }
    th, td { border: 1px solid #e5e7eb; padding: 8px 10px; text-align: left; font-size: 13px; }
    th { background: #f3f4f6; font-weight: 600; color: #374151; }
    tr:nth-child(even) { background: #f9fafb; }
    tr:hover { background: #eff6ff; }
</style>
"@

        # Check if file exists
        if (Test-Path $OutputFilePath) {
            # File exists - append new sections before closing body tag
            $existingContent = Get-Content -Path $OutputFilePath -Raw
            $newSectionsHtml = $sectionsHtml -join "`n"
            $updatedContent = $existingContent -replace '</body>', "$newSectionsHtml`n</body>"
            $updatedContent | Set-Content -Path $OutputFilePath -Encoding UTF8
            
            Write-SysFlowLog -LogLevel 'Info' -Message 'Statistics appended to existing unified HTML' -Details "File: $OutputFilePath; New sections: $($StatsHashtable.Count); Date: $runDate; Time: $runTime" -LogFilePath $defaultLogPath
        }
        else {
            # File doesn't exist - create new HTML file
            $meta = "Generated: $runDate $runTime"
            $allSectionsHtml = $sectionsHtml -join "`n"
            $content = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>$PageTitle</title>
$style
</head>
<body>
<h1>$PageTitle</h1>
<div class="meta">$meta</div>
$allSectionsHtml
</body>
</html>
"@

            $content | Set-Content -Path $OutputFilePath -Encoding UTF8
            Write-SysFlowLog -LogLevel 'Info' -Message 'New unified HTML report created' -Details "File: $OutputFilePath; Sections: $($StatsHashtable.Count); Date: $runDate; Time: $runTime" -LogFilePath $defaultLogPath
        }
    }
    catch {
        Write-Error "Failed to export statistics to unified HTML: $_"
        Write-SysFlowLog -LogLevel 'Error' -Message 'Failed to export statistics to unified HTML' -Details "Error: $_" -LogFilePath $defaultLogPath
    }
}

# End of Export-UnifiedStatsToHtml function
