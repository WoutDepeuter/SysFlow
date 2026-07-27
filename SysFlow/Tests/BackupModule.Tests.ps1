BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "..\Modules\BackupModule\BackupModule.psm1"
    Import-Module $modulePath -Force

    # Set up global test variables
    $script:testRoot = Join-Path $env:TEMP "SysFlow_Pester_$(Get-Date -Format 'yyyyMMddHHmmss')"
    $script:sourceDir = Join-Path $script:testRoot "SourceData"
    $script:backupDir = Join-Path $script:testRoot "Backups"
    $script:restoreDir = Join-Path $script:testRoot "Restored"
    $script:testBackupPath = $null

    # Create directories and dummy files
    New-Item -ItemType Directory -Path $script:sourceDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:backupDir -Force | Out-Null
    
    "Test content 1" | Out-File (Join-Path $script:sourceDir "file1.txt")
    "Test content 2" | Out-File (Join-Path $script:sourceDir "file2.txt")
}

AfterAll {
    # Clean up temp files after tests finish
    if (Test-Path $script:testRoot) {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "BackupModule Tests" {

    Context "New-Backup" {
        It "Should successfully create a ZIP archive from the source directory" {
            $result = New-Backup -PathsToBackup $script:sourceDir -BackupDestination $script:backupDir
            $script:testBackupPath = $result.BackupPath
            
            $result.Size | Should -BeGreaterThan 0
            Test-Path $result.BackupPath | Should -Be $true
        }
    }

    Context "Test-BackupIntegrity" {
        It "Should return `$true for the newly created, uncorrupted backup archive" {
            $isValid = Test-BackupIntegrity -BackupFilePath $script:testBackupPath
            $isValid | Should -Be $true
        }
    }

    Context "Restore-Backup" {
        It "Should successfully extract the backup archive to the restore destination" {
            $result = Restore-Backup -BackupFilePath $script:testBackupPath -RestoreDestination $script:restoreDir
            
            $result.Success | Should -Be $true
            $result.FilesRestored | Should -BeGreaterThan 0
            
            # Check if our dummy files are actually there
            Test-Path (Join-Path $script:restoreDir "file1.txt") | Should -Be $true
        }
    }

    Context "Remove-Backup" {
        It "Should delete the backup file when the -Force flag is used" {
            # Act
            $result = Remove-Backup -BackupFilePath $script:testBackupPath -Force
            
            # Assert
            $result.Status | Should -Be "Removed"
            Test-Path $script:testBackupPath | Should -Be $false
        }
    }
}