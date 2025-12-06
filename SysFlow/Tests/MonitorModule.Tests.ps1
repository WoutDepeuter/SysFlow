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
}

Describe "Get-StorageStats" {
    It "Should return an object with storage information" {
        $result = Get-StorageStats
        $result | Should Not BeNullOrEmpty
    }

    It "Should have data returned" {
        $result = Get-StorageStats
        $result | Should Not Be $null
    }
}

Describe "Get-Uptime" {
    It "Should return an object with uptime information" {
        $result = Get-Uptime
        $result | Should Not BeNullOrEmpty
    }
}