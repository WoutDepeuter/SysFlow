#function to update software using winget or chocolatey
function Update-Software {
    <#
    .SYNOPSIS
        Updates software via Winget or Chocolatey.
    .DESCRIPTION
        The Update-Software function updates a specified software package on the system.
        It supports updating via the Winget and Chocolatey package managers.
    .PARAMETER PackageName
        The name or ID of the package to update.
    .PARAMETER Manager
        Package manager to use for updating ('winget' or 'choco').
    .NOTES
    #>
    param(
        
        [string]$PackageName,
        [ValidateSet('winget', 'choco')]
        [string]$Manager = 'winget'

        
    )

    # Ensure Get-SoftwareList is available even if this script is dot-sourced directly
    if (-not (Get-Command -Name Get-SoftwareList -ErrorAction SilentlyContinue)) {
        try {
            $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
            $helperPath = Join-Path $scriptRoot 'Get-SoftwareList.ps1'
            if (Test-Path $helperPath) { . $helperPath } else { Write-Warning "Get-SoftwareList.ps1 not found at $helperPath" }
        } catch { Write-Warning "Failed to load Get-SoftwareList.ps1: $_" }
    }

    # Track status for the return object
    $status = "Failed"
    $errorDetails = $null

    # If no package name provided, show interactive, paginated list with search
    if (-not $PackageName) {
        Write-Host "`n=== Installed Software (interactive selector) ===" -ForegroundColor Cyan
        $software = Get-SoftwareList

        if (-not $software -or $software.Count -eq 0) {
            Write-Host "No software found." -ForegroundColor Yellow
            return
        }

        $pageSize = 10
        $page = 0
        $filtered = $software

        function Show-Page {
            param($items, $page, $pageSize)
            Clear-Host
            Write-Host "Installed Software (Page $([int]($page + 1)) of $([int][Math]::Ceiling($items.Count / $pageSize)))" -ForegroundColor Cyan
            $start = $page * $pageSize
            $slice = $items | Select-Object -Skip $start -First $pageSize
            for ($i = 0; $i -lt $slice.Count; $i++) {
                $globalIndex = $start + $i + 1
                $item = $slice[$i]
                $displayId = if ($item.PSObject.Properties.Match('ID')) { $item.ID } else { $item.Name }
                Write-Host "[$globalIndex] $($item.Name) (v$($item.Version)) - ID: $displayId" -ForegroundColor White
            }
            Write-Host "`nCommands: [n]ext, [p]rev, [s]earch <term>, <number> to select, [q]uit" -ForegroundColor DarkGray
        }

        while ($true) {
            Show-Page -items $filtered -page $page -pageSize $pageSize
            $input = Read-Host "Enter command"
            if (-not $input) { Write-Host "Cancelled." -ForegroundColor Yellow; return }

            switch -Regex ($input) {
                '^[Nn]$' {
                    if ((($page + 1) * $pageSize) -lt $filtered.Count) { $page++ } else { Write-Host "Already at last page." -ForegroundColor DarkYellow }
                    continue
                }
                '^[Pp]$' {
                    if ($page -gt 0) { $page-- } else { Write-Host "Already at first page." -ForegroundColor DarkYellow }
                    continue
                }
                '^[Qq]$' {
                    Write-Host "Cancelled." -ForegroundColor Yellow
                    return
                }
                '^[Ss]\s+(.+)' {
                    $term = $Matches[1]
                    $filtered = $software | Where-Object { $_.Name -match [regex]::Escape($term) -or (($_.PSObject.Properties.Match('ID')) -and ($_.ID -match [regex]::Escape($term))) }
                    if (-not $filtered -or $filtered.Count -eq 0) { Write-Host "No matches for '$term'." -ForegroundColor Yellow; $filtered = $software }
                    $page = 0
                    continue
                }
                '^(\d+)$' {
                    $sel = [int]$Matches[1]
                    if ($sel -lt 1 -or $sel -gt $filtered.Count) {
                        Write-Host "Selection out of range." -ForegroundColor Red
                        continue
                    }
                    $PackageName = $filtered[$sel - 1].PSObject.Properties.Match('ID') ? $filtered[$sel - 1].ID : $filtered[$sel - 1].Name
                    Write-Host "`nSelected: $PackageName" -ForegroundColor Green
                    break
                }
                default {
                    Write-Host "Unknown command." -ForegroundColor Yellow
                    continue
                }
            }
        }
    }

    # Auto-detect manager if not specified
    if (-not $Manager) {
        Write-Host "`nDetecting which manager installed '$PackageName'..." -ForegroundColor Yellow
        $detectedManager = Get-InstalledBy -PackageName $PackageName
        
        if ($detectedManager -ne 'unknown') {
            Write-Host "✓ Detected: $detectedManager" -ForegroundColor Green
            $Manager = $detectedManager
        } else {
            Write-Host "Could not auto-detect. Please specify manager." -ForegroundColor Yellow
            Write-Host "1. Winget"
            Write-Host "2. Chocolatey"
            $managerChoice = Read-Host "Select package manager (1 or 2)"
            $Manager = if ($managerChoice -eq '2') { 'choco' } else { 'winget' }
            Write-Host "Using: $Manager" -ForegroundColor Green
        }
    }

    try {
        # Determine flow per manager and run commands robustly
        if ($Manager -eq 'winget') {
            Write-Host "Updating $PackageName using Winget..." -ForegroundColor Cyan

            # winget accepts either an ID (contains a dot) or a name; prefer --id when an identifier looks like an ID
            $wingetArgs = @('upgrade')
            if ($PackageName -match '\.') {
                $wingetArgs += @('--id', $PackageName)
            } else {
                # use the package name as the query argument
                $wingetArgs += $PackageName
            }
            $wingetArgs += @('--silent','--accept-source-agreements','--accept-package-agreements')

            $proc = Start-Process -FilePath (Get-Command winget).Source -ArgumentList $wingetArgs -NoNewWindow -PassThru -Wait -ErrorAction Stop
            if ($proc.ExitCode -ne 0) { throw "Winget returned exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq 'choco') {
            Write-Host "Updating $PackageName using Chocolatey..." -ForegroundColor Cyan
            $proc = Start-Process -FilePath (Get-Command choco).Source -ArgumentList @('upgrade', $PackageName, '-y') -NoNewWindow -PassThru -Wait -ErrorAction Stop
            if ($proc.ExitCode -ne 0) { throw "Chocolatey returned exit code $($proc.ExitCode)" }
        }

        Write-Host "✓ Update command executed for $PackageName." -ForegroundColor Green
        $status = 'Success'
    }
    catch {
        $status = 'Error'
        $errorDetails = $_.Exception.Message
        Write-Error "Update failed: $_"
    }

    return [PSCustomObject]@{
        Timestamp   = Get-Date
        Action      = 'Update-Software'
        PackageName = $PackageName
        Manager     = $Manager
        Status      = $status
        Details     = $errorDetails
    }
}


# End of Update-Software function
