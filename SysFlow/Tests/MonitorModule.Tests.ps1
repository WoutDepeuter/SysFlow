# Import the module before running tests
$modulePath = Join-Path $PSScriptRoot '..\Modules\MonitorModule\MonitorModule.psm1'
Import-Module $modulePath -Force

Describe "Get-CPUStats" {
    It "Should return an object with CPU information" {
        $result = Get-CPUStats
        $result | Should Not BeNullOrEmpty
    }

    It "Should have NumberOfLogicalProcessors property" {
        $result = Get-CPUStats
        $result.NumberOfLogicalProcessors | Should Not BeNullOrEmpty
    }

    It "Should have LoadPercentage property" {
        $result = Get-CPUStats
        $result.LoadPercentage | Should Not BeNullOrEmpty
    }

    It "LoadPercentage should be between 0 and 100" {
        $result = Get-CPUStats
        ($result.LoadPercentage -ge 0 -and $result.LoadPercentage -le 100) | Should Be $true
    }

    It "Should not throw error with custom threshold" {
        { Get-CPUStats -threshold 75 } | Should Not Throw
    }
}

Describe "Get-RamStats" {
    It "Should return an object with RAM information" {
        $result = Get-RamStats
        $result | Should Not BeNullOrEmpty
    }

    It "Should have Total property" {
        $result = Get-RamStats
        $result.Total | Should Not BeNullOrEmpty
    }

    It "Should have Free property" {
        $result = Get-RamStats
        $result.Free | Should Not BeNullOrEmpty
    }

    It "Free should not exceed Total" {
        $result = Get-RamStats
        ($result.Free -le $result.Total) | Should Be $true
    }

    It "UsedPercent should be between 0 and 100" {
        $result = Get-RamStats
        ($result.UsedPercent -ge 0 -and $result.UsedPercent -le 100) | Should Be $true
    }

    It "Should not throw error with custom threshold" {
        { Get-RamStats -threshold 75 } | Should Not Throw
    }
}

Describe "Get-StorageStats" {
    It "Should return an object with storage information" {
        $result = Get-StorageStats
        $result | Should Not BeNullOrEmpty
    }

    It "Should return array or collection of drives" {
        $result = Get-StorageStats
        ($result -is [array] -or $result.Count -ge 1) | Should Be $true
    }

    It "Should not throw error" {
        { Get-StorageStats } | Should Not Throw
    }
}

Describe "Get-Uptime" {
    It "Should return an object with uptime information" {
        $result = Get-Uptime
        $result | Should Not BeNullOrEmpty
    }

    It "Should have Uptime property or return TimeSpan" {
        $result = Get-Uptime
        ($result -is [timespan] -or $result.Uptime -ne $null) | Should Be $true
    }

    It "Uptime should be a positive value" {
        $result = Get-Uptime
        if ($result -is [timespan]) {
            ($result.TotalSeconds -gt 0) | Should Be $true
        } else {
            ($result.Uptime.TotalSeconds -gt 0) | Should Be $true
        }
    }
}