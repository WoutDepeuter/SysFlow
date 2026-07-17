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
        [array]$SoftwareList,
        [int]$SoftwarePageSize = 50,
        [int]$ProcessPageSize = 50,

        [Parameter(Mandatory=$true)]
        [string]$OutputFilePath,

        [string]$Title = 'SysFlow System Report',

        [bool]$ExportCsv = $true,
        [string]$CsvDirectory = $null
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

        # CSV export helpers
        if (-not $CsvDirectory) { $CsvDirectory = $outputDir }
        function Sanitize-FileName { param($n) return ($n -replace '[\\/:*?"<>|]', '_') }

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

        function Get-PaginationScript {
            param([int]$SoftwarePageSize, [int]$ProcessPageSize)
            $swps = $SoftwarePageSize
            $prps = $ProcessPageSize
            $out = "<script>`n"
            $out += "var swPageSize = $swps; var procPageSize = $prps;`n"
            $out += @'
(function() {
  var pageSize = swPageSize;
  var table = document.getElementById('softwareTable');
  if (!table) return;
  var tbody = table.getElementsByTagName('tbody')[0];
  var rows = Array.prototype.slice.call(tbody.rows);
  var total = rows.length;
  var totalPages = Math.max(1, Math.ceil(total / pageSize));
  var pager = document.getElementById('softwarePager');
  function showPage(n) {
    var start = (n-1)*pageSize;
    var end = start + pageSize;
    rows.forEach(function(r, i) { r.style.display = (i>=start && i<end) ? "" : "none"; });
    if (!pager) return;
    pager.innerHTML = "";
    for (var i=1;i<=totalPages;i++) {
      var a = document.createElement('a');
      a.href = 'javascript:void(0)';
      a.textContent = i;
      (function(i){ a.addEventListener('click', function(){ showPage(i); }); })(i);
      if (i===n) { a.className = "active"; }
      pager.appendChild(a);
    }
  }
  showPage(1);
})();
(function() {
  var pageSize = procPageSize;
  var table = document.getElementById('processTable');
  if (!table) return;
  var tbody = table.getElementsByTagName('tbody')[0];
  var rows = Array.prototype.slice.call(tbody.rows);
  var total = rows.length;
  var totalPages = Math.max(1, Math.ceil(total / pageSize));
  var pager = document.getElementById('processPager');
  function showPage(n) {
    var start = (n-1)*pageSize;
    var end = start + pageSize;
    rows.forEach(function(r, i) { r.style.display = (i>=start && i<end) ? "" : "none"; });
    if (!pager) return;
    pager.innerHTML = "";
    for (var i=1;i<=totalPages;i++) {
      var a = document.createElement('a');
      a.href = 'javascript:void(0)';
      a.textContent = i;
      (function(i){ a.addEventListener('click', function(){ showPage(i); }); })(i);
      if (i===n) { a.className = "active"; }
      pager.appendChild(a);
    }
  }
  showPage(1);
})();
'@
            $out += "`n</script>"
            return $out
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
        /* Pagination styles for software list */
        .pager { margin: 12px 0 24px 0; }
        .pager a { margin-right: 6px; padding: 6px 10px; background: #fff; border: 1px solid #e5e7eb; color: #374151; text-decoration: none; border-radius: 4px; }
        .pager a.active { background: #111827; color: #fff; }
    </style>
    "@

        $meta = "Generated: $runDate $runTime"
        $sections = ""

        # CPU Section
        if ($CpuStats) {
            $cpuRows = Add-Timestamps -Stats $CpuStats
            # Export CSV for this section
            if ($ExportCsv -and $cpuRows) {
                $base = [IO.Path]::GetFileNameWithoutExtension($OutputFilePath)
                $safeSectionTitle = Sanitize-FileName 'CPU Statistics'
                $csvName = "${base}-$safeSectionTitle.csv"
                $csvPath = Join-Path $CsvDirectory $csvName
                try {
                    if (Get-Command Export-StatToCsv -ErrorAction SilentlyContinue) { Export-StatToCsv -Stats $cpuRows -OutputFilePath $csvPath | Out-Null }
                    else { $cpuRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 }
                } catch { Write-Warning "Failed to export CPU CSV: $_" }
            }
            $cpuTable = $cpuRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>CPU Statistics</h2>$cpuTable</div>"
        }

        # RAM Section
        if ($RamStats) {
            $ramRows = Add-Timestamps -Stats $RamStats
            if ($ExportCsv -and $ramRows) {
                $base = [IO.Path]::GetFileNameWithoutExtension($OutputFilePath)
                $safeSectionTitle = Sanitize-FileName 'RAM Statistics'
                $csvName = "${base}-$safeSectionTitle.csv"
                $csvPath = Join-Path $CsvDirectory $csvName
                try {
                    if (Get-Command Export-StatToCsv -ErrorAction SilentlyContinue) { Export-StatToCsv -Stats $ramRows -OutputFilePath $csvPath | Out-Null }
                    else { $ramRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 }
                } catch { Write-Warning "Failed to export RAM CSV: $_" }
            }
            $ramTable = $ramRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>RAM Statistics</h2>$ramTable</div>"
        }

        # Storage Section
        if ($StorageStats) {
            $storageRows = Add-Timestamps -Stats $StorageStats
            if ($ExportCsv -and $storageRows) {
                $base = [IO.Path]::GetFileNameWithoutExtension($OutputFilePath)
                $safeSectionTitle = Sanitize-FileName 'Storage Statistics'
                $csvName = "${base}-$safeSectionTitle.csv"
                $csvPath = Join-Path $CsvDirectory $csvName
                try {
                    if (Get-Command Export-StatToCsv -ErrorAction SilentlyContinue) { Export-StatToCsv -Stats $storageRows -OutputFilePath $csvPath | Out-Null }
                    else { $storageRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 }
                } catch { Write-Warning "Failed to export Storage CSV: $_" }
            }
            $storageTable = $storageRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>Storage Statistics</h2>$storageTable</div>"
        }

        # Uptime Section
        if ($UptimeStats) {
            $uptimeRows = Add-Timestamps -Stats $UptimeStats
            if ($ExportCsv -and $uptimeRows) {
                $base = [IO.Path]::GetFileNameWithoutExtension($OutputFilePath)
                $safeSectionTitle = Sanitize-FileName 'Uptime Statistics'
                $csvName = "${base}-$safeSectionTitle.csv"
                $csvPath = Join-Path $CsvDirectory $csvName
                try {
                    if (Get-Command Export-StatToCsv -ErrorAction SilentlyContinue) { Export-StatToCsv -Stats $uptimeRows -OutputFilePath $csvPath | Out-Null }
                    else { $uptimeRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 }
                } catch { Write-Warning "Failed to export Uptime CSV: $_" }
            }
            $uptimeTable = $uptimeRows | ConvertTo-Html -Fragment
            $sections += "<div class='section'><h2>System Uptime</h2>$uptimeTable</div>"
        }

        # Process Section (paginated)
        if ($ProcessStats) {
            $processRows = Add-Timestamps -Stats $ProcessStats
            if ($ExportCsv -and $processRows) {
                $base = [IO.Path]::GetFileNameWithoutExtension($OutputFilePath)
                $safeSectionTitle = Sanitize-FileName 'Process Statistics'
                $csvName = "${base}-$safeSectionTitle.csv"
                $csvPath = Join-Path $CsvDirectory $csvName
                try {
                    if (Get-Command Export-StatToCsv -ErrorAction SilentlyContinue) { Export-StatToCsv -Stats $processRows -OutputFilePath $csvPath | Out-Null }
                    else { $processRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 }
                } catch { Write-Warning "Failed to export Process CSV: $_" }
            }
            # Build HTML table manually so we can paginate client-side
            $processRows = $processRows | Sort-Object Name
            $first = $processRows | Select-Object -First 1
            $cols = @()
            if ($first) { $cols = $first.PSObject.Properties | ForEach-Object { $_.Name } }

            function Html-Encode { param([string]$s) if ($null -eq $s) { return '' } return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' -replace "'","&#39;") }

            $tableHtml = "<table id='processTable'><thead><tr>"
            foreach ($c in $cols) { $tableHtml += "<th>$c</th>" }
            $tableHtml += "</tr></thead><tbody>"
            foreach ($r in $processRows) {
                $tableHtml += "<tr>"
                foreach ($c in $cols) {
                    $val = $r.$c
                    $enc = Html-Encode -s ([string]$val)
                    $tableHtml += "<td>$enc</td>"
                }
                $tableHtml += "</tr>"
            }
            $tableHtml += "</tbody></table>"

            $sections += "<div class='section'><h2>Active Processes</h2>$tableHtml<div id='processPager' class='pager'></div></div>"
        }
        

        # Software Section (paginated)
        $scripts = ""
        if ($SoftwareList) {
            $softwareRows = Add-Timestamps -Stats $SoftwareList
            if ($ExportCsv -and $softwareRows) {
                $base = [IO.Path]::GetFileNameWithoutExtension($OutputFilePath)
                $safeSectionTitle = Sanitize-FileName 'Installed Software'
                $csvName = "${base}-$safeSectionTitle.csv"
                $csvPath = Join-Path $CsvDirectory $csvName
                try {
                    if (Get-Command Export-StatToCsv -ErrorAction SilentlyContinue) { Export-StatToCsv -Stats $softwareRows -OutputFilePath $csvPath | Out-Null }
                    else { $softwareRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 }
                } catch { Write-Warning "Failed to export Software CSV: $_" }
            }

            # Build HTML table manually so we can paginate client-side
            $softwareRows = $softwareRows | Sort-Object Name
            $first = $softwareRows | Select-Object -First 1
            $cols = @()
            if ($first) { $cols = $first.PSObject.Properties | ForEach-Object { $_.Name } }

            function Html-Encode { param([string]$s) if ($null -eq $s) { return '' } return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' -replace "'","&#39;") }

            $tableHtml = "<table id='softwareTable'><thead><tr>"
            foreach ($c in $cols) { $tableHtml += "<th>$c</th>" }
            $tableHtml += "</tr></thead><tbody>"
            foreach ($r in $softwareRows) {
                $tableHtml += "<tr>"
                foreach ($c in $cols) {
                    $val = $r.$c
                    $enc = Html-Encode -s ([string]$val)
                    $tableHtml += "<td>$enc</td>"
                }
                $tableHtml += "</tr>"
            }
            $tableHtml += "</tbody></table>"

            $sections += "<div class='section'><h2>Installed Software</h2>$tableHtml<div id='softwarePager' class='pager'></div></div>"
        }

        # Generate pagination scripts after all sections are built
        $scripts = Get-PaginationScript -SoftwarePageSize $SoftwarePageSize -ProcessPageSize $ProcessPageSize

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
$scripts
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
