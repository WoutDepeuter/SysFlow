function Search-Software {
    <#
    .SYNOPSIS
        Search for software packages using a package manager.
    
    .DESCRIPTION
        Searches for software using winget or Chocolatey and returns
        results as a list of objects that can be installed.
    
    .PARAMETER SearchTerm
        The software name or partial name to search for.
    
    .PARAMETER Engine
        Package manager to use: 'winget' or 'choco'. Defaults to config setting.
    
    .OUTPUTS
        PSCustomObject with properties: Name, Version, ID
    
    .EXAMPLE
        $results = Search-Software -SearchTerm "python" -Engine "winget"
        $results | Format-Table
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SearchTerm,

        [Parameter(Mandatory=$false)]
        [ValidateSet('winget', 'choco')]
        [string]$Engine
    )

    $results = @()

    if ([string]::IsNullOrEmpty($Engine)) {
        $configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.psd1"
        if (Test-Path $configPath) {
            $config = Import-PowerShellDataFile -Path $configPath
            $Engine = $config.DefaultPackageManager 
        } 
        
        if ([string]::IsNullOrEmpty($Engine)) {
            Write-Warning "Could not read default engine from config. Defaulting to winget."
            $Engine = 'winget'
        }
    }

    # Search based on engine
    if ($Engine -eq 'choco') {
        Write-Host "Searching for software using Chocolatey..." -ForegroundColor Cyan
        try {
            $rawOutput = & choco search $SearchTerm 2>$null
            # Filter: remove header, separators, footer info lines, and lines with leading spaces
            $lines = @($rawOutput -split "`n") | Where-Object { $_ -and -not ($_ -match '^(Chocolatey|---|.*packages found|Did you know|Features|https:|Learn more|Package Synchronizer|\s)') }
            
            foreach ($line in $lines) {
                # Format: "name version [status] description"
                $match = $line -match '^(\S+)\s+(\S+)\s+'
                if ($match) {
                    $parts = $line -split '\s+', 3
                    if ($parts.Count -ge 2) {
                        $results += [PSCustomObject]@{
                            Name    = $parts[0].Trim()
                            Version = $parts[1].Trim()
                            ID      = $parts[0].Trim()
                            Engine  = 'choco'
                        }
                    }
                }
            }
        }
        catch {
            Write-Host "Error searching Chocolatey: $_" -ForegroundColor Red
            return @()
        }
    }
    else {
        Write-Host "Searching for software using Winget..." -ForegroundColor Cyan
        try {
            $rawOutput = & winget search $SearchTerm --source winget 2>$null
            $lines = $rawOutput -split "`n" | Where-Object { $_ -and $_ -notmatch '^Name' }
            
            foreach ($line in $lines) {
                # Skip separator lines and empty lines
                if ($line -match '^\-+' -or [string]::IsNullOrWhiteSpace($line)) {
                    continue
                }
                
                # Parse winget format: Name | ID | Version | Source
                $parts = @($line -split '\s+' | Where-Object { $_ })
                if ($parts.Count -ge 3) {
                    $results += [PSCustomObject]@{
                        Name    = $parts[0]
                        ID      = $parts[1]
                        Version = $parts[2]
                        Engine  = 'winget'
                    }
                }
            }
        }
        catch {
            Write-Host "Error searching Winget: $_" -ForegroundColor Red
            return @()
        }
    }

    # Display results
    if ($results.Count -gt 0) {
        Write-Host "`nSoftware found matching '$SearchTerm':" -ForegroundColor Green
        $results | Format-Table -Property Name, ID, Version -AutoSize
    } else {
        Write-Host "No software found matching '$SearchTerm' using $Engine." -ForegroundColor Yellow
    }

    return $results
}