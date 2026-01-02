# Import the ReportingModule before running tests
$modulePath = Join-Path $PSScriptRoot '..\Modules\ReportingModule\ReportingModule.psm1'
Import-Module $modulePath -Force

Describe "Write-SysFlowLog" {
    It "Should create the log file when a custom path is provided" {
        $tempDir = Join-Path $env:TEMP "SysFlow_LogTests"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        $logFile = Join-Path $tempDir "test-log-create.log"
        if (Test-Path $logFile) {
            Remove-Item $logFile -Force
        }

        Write-SysFlowLog -LogLevel Info -Message "Test create log" -LogFilePath $logFile

        Test-Path $logFile | Should Be $true
    }

    It "Should write log level and message to the log file" {
        $tempDir = Join-Path $env:TEMP "SysFlow_LogTests"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        $logFile = Join-Path $tempDir "test-log-content.log"
        if (Test-Path $logFile) {
            Remove-Item $logFile -Force
        }

        $message = "Content test message"
        Write-SysFlowLog -LogLevel Warning -Message $message -LogFilePath $logFile

        $content = Get-Content -Path $logFile -Raw
            $content | Should Match "\[Warning\]"
            $content | Should Match $message
    }

    It "Should include details when provided" {
        $tempDir = Join-Path $env:TEMP "SysFlow_LogTests"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        $logFile = Join-Path $tempDir "test-log-details.log"
        if (Test-Path $logFile) {
            Remove-Item $logFile -Force
        }

        $details = "Extra details for testing"
        Write-SysFlowLog -LogLevel Error -Message "Details test" -Details $details -LogFilePath $logFile

        $content = Get-Content -Path $logFile -Raw
            $content | Should Match "Details: "
            $content | Should Match $details
    }

    It "Should append multiple log entries to the same file" {
        $tempDir = Join-Path $env:TEMP "SysFlow_LogTests"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        $logFile = Join-Path $tempDir "test-log-append.log"
        if (Test-Path $logFile) {
            Remove-Item $logFile -Force
        }

        Write-SysFlowLog -LogLevel Info -Message "First entry" -LogFilePath $logFile
        Start-Sleep -Milliseconds 100
        Write-SysFlowLog -LogLevel Info -Message "Second entry" -LogFilePath $logFile

        $lines = Get-Content -Path $logFile
        ($lines.Count -ge 2) | Should Be $true
        $lines[0] | Should Match "First entry"
        $lines[1] | Should Match "Second entry"
    }
}
