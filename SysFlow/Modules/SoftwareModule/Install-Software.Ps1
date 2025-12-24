function Find-PackageId {
    <#
    .SYNOPSIS
        Searches for a package ID by name using Winget or Chocolatey.
    
    .PARAMETER PackageName
        The name of the package to search for.
    
    .PARAMETER Manager
        Package manager to search in ('winget' or 'choco').
    
    .OUTPUTS
        Returns the package ID (string) or $null if not found.
    #>
    param(
        [string]$PackageName,
        [ValidateSet('winget', 'choco')]
        [string]$Manager = 'winget'
    )

    try {
        if ($Manager -eq 'winget') {
            $results = winget search $PackageName 2>$null | Select-Object -First 5
            if ($results) {
                # Parse first result: format is "Name                                     Id                                     Version"
                # Extract the Id column (typically between Name and Version)
                foreach ($line in $results) {
                    if ($line -match '\s+(\S+\.[\w.]+)\s+[\d.]+') {
                        return $matches[1]
                    }
                }
            }
        }
        elseif ($Manager -eq 'choco') {
            $results = choco search $PackageName --exact 2>$null | Select-Object -First 2
            if ($results) {
                # Chocolatey format: "package | version"
                foreach ($line in $results) {
                    if ($line -match '^([a-zA-Z0-9._-]+)\s+') {
                        return $matches[1]
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Search failed: $_"
    }

    return $null
}

function Install-Software {
    <#
    .SYNOPSIS
        Installs software via Winget or Chocolatey with automatic ID lookup.

    .DESCRIPTION
        The Install-Software function installs a specified software package on the system.
        It supports installation via the Winget and Chocolatey package managers.
        If the provided name is not an exact ID, the function automatically searches for and retrieves the package ID.

    .PARAMETER SoftwareName
        The name or ID of the software package (e.g., 'firefox', 'git', '7zip', 'Git.Git').

    .PARAMETER Manager
        The package manager to use ('winget' or 'choco').
        Default is 'winget'.

    .EXAMPLE
        Install-Software -SoftwareName "7zip"
        Installs 7zip using the default manager (Winget), automatically searching for the ID.

    .EXAMPLE
        Install-Software -SoftwareName "googlechrome" -Manager "choco"
        Installs Google Chrome using Chocolatey.

    .OUTPUTS
        PSCustomObject containing the installation status.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$SoftwareName,

        [Parameter(Mandatory=$false)]
        [ValidateSet('winget', 'choco')]
        [string]$Manager = 'winget'
    )

    # Track status for the return object
    $status = "Failed"
    $errorMessage = $null
    $resolvedId = $SoftwareName

    # Attempt to resolve ID if it doesn't look like a winget ID (contains dot) and manager is winget
    if ($Manager -eq 'winget' -and $SoftwareName -notmatch '\.') {
        Write-Host "Searching for package ID: $SoftwareName..." -ForegroundColor Yellow
        $resolvedId = Find-PackageId -PackageName $SoftwareName -Manager 'winget'
        if ($resolvedId) {
            Write-Host "✓ Found package ID: $resolvedId" -ForegroundColor Green
        } else {
            Write-Warning "Could not find exact ID for '$SoftwareName'. Attempting install with name..."
        }
    }

    try {
        switch ($Manager) {
            'winget' {
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    Write-Host "Installing '$SoftwareName' using Winget..." -ForegroundColor Cyan
                    # Use resolved ID, with --silent to suppress popups
                    winget install --id $resolvedId --silent --accept-source-agreements --accept-package-agreements
                    
                    # Winget does not always return exit codes, so we assume no error = success
                    $status = "Success" 
                    Write-Host "✓ Winget execution completed." -ForegroundColor Green
                } else {
                    throw "Winget is not installed on this system."
                }
            }
            'choco' {
                if (Get-Command choco -ErrorAction SilentlyContinue) {
                    Write-Host "Installing '$SoftwareName' using Chocolatey..." -ForegroundColor Cyan
                    # Chocolatey works with package names directly, no ID resolution needed
                    choco install $SoftwareName -y
                    
                    if ($LASTEXITCODE -eq 0) {
                        $status = "Success"
                        Write-Host "✓ Installation via Chocolatey successful." -ForegroundColor Green
                    } else {
                        throw "Chocolatey returned exit code $LASTEXITCODE"
                    }
                } else {
                    throw "Chocolatey is not installed on this system."
                }
            }
        }
    }
    catch {
        $status = "Error"
        $errorMessage = $_.Exception.Message
        Write-Error "Failed to install $SoftwareName`: $errorMessage"
    }

    # Return object for reporting
    return [PSCustomObject]@{
        Timestamp    = Get-Date
        Action       = "Install-Software"
        PackageName  = $SoftwareName
        ResolvedId   = $resolvedId
        Manager      = $Manager
        Status       = $status
        Details      = $errorMessage
    }
}
