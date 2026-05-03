function Search-Software {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SearchTerm,

        [Parameter(Mandatory=$false)]
        [ValidateSet('winget', 'choco')]
        [string]$Engine
    )

    $results = $null

    if ([string]::IsNullOrEmpty($Engine)) {
        # Assuming this module sits in SysFlow/Modules/SoftwareModule/
        # Navigate up to the SysFlow root to find config.psd1
        $configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.psd1"

        if (Test-Path $configPath) {
            $config = Import-PowerShellDataFile -Path $configPath
            # Replace 'DefaultPackageManager' with the actual key you use in your psd1
            $Engine = $config.DefaultPackageManager 
        } 
        
        # Fallback just in case the config file is missing or the key is empty
        if ([string]::IsNullOrEmpty($Engine)) {
            Write-Warning "Could not read default engine from config. Defaulting to winget."
            $Engine = 'winget'
        }
    }

    # Route the search based on the engine retrieved from config
    if ($Engine -eq 'choco') {
        Write-Host "Searching for software using Chocolatey..." -ForegroundColor Cyan
        $results = choco search $SearchTerm --limit-output | Select-Object -Skip 1
    }
    elseif ($Engine -eq 'winget') {
        Write-Host "Searching for software using Winget..." -ForegroundColor Cyan
        $results = winget search $SearchTerm --source winget | Select-Object -Skip 1
    }

    # Check if any results were returned
    if (-not $results -or $results.Count -eq 0) {
        Write-Output "No software found matching '$SearchTerm' using $Engine."
        return
    }

    # Display results to the user
    Write-Output "Software found matching '$SearchTerm':"
    $results | ForEach-Object { Write-Output $_ }
}