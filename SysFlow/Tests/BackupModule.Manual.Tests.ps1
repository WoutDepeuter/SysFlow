<#
.SYNOPSIS
    Manual test script for BackupModule functions
.DESCRIPTION
    Tests New-Backup, Restore-Backup, and Remove-Backup with temporary test data
#>

# Import the BackupModule
$BackupModulePath = Join-Path $PSScriptRoot '..\Modules\BackupModule\BackupModule.psm1'
if (Test-Path $BackupModulePath) {
    Import-Module $BackupModulePath -Force
} else {
    Write-Error "BackupModule not found at: $BackupModulePath"
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BACKUP MODULE MANUAL TEST SUITE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Setup: Create temporary test directories and files
$testRoot = Join-Path $env:TEMP "SysFlow_BackupTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
$sourceDir = Join-Path $testRoot "SourceData"
$backupDir = Join-Path $testRoot "Backups"
$restoreDir = Join-Path $testRoot "Restored"

try {
    Write-Host "[SETUP] Creating test directories..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    New-Item -ItemType Directory -Path $restoreDir -Force | Out-Null

    # Create test files
    "Test content 1" | Out-File (Join-Path $sourceDir "file1.txt")
    "Test content 2" | Out-File (Join-Path $sourceDir "file2.txt")
    
    # Create a subdirectory with files
    $subDir = Join-Path $sourceDir "SubFolder"
    New-Item -ItemType Directory -Path $subDir -Force | Out-Null
    "Nested file" | Out-File (Join-Path $subDir "nested.txt")
    
    Write-Host "✓ Test structure created at: $testRoot" -ForegroundColor Green
    Write-Host ""

    # TEST 1: Create Backup
    Write-Host "[TEST 1] Creating backup..." -ForegroundColor Cyan
    $backupResult = New-Backup -PathsToBackup $sourceDir -BackupDestination $backupDir -Verbose
    
    if ($backupResult -and (Test-Path $backupResult.BackupPath)) {
        Write-Host "✓ Backup created successfully" -ForegroundColor Green
        Write-Host "  Path: $($backupResult.BackupPath)" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round($backupResult.Size / 1KB, 2)) KB" -ForegroundColor Gray
    } else {
        Write-Host "✗ Backup creation failed" -ForegroundColor Red
        exit 1
    }
    Write-Host ""

    # TEST 2: Verify backup contains files
    Write-Host "[TEST 2] Verifying backup contents..." -ForegroundColor Cyan
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($backupResult.BackupPath)
    $entries = $zipArchive.Entries | Select-Object -ExpandProperty FullName
    $zipArchive.Dispose()
    
    $expectedFiles = @('file1.txt', 'file2.txt', 'SubFolder/nested.txt', 'backup-manifest')
    $allFound = $true
    foreach ($expected in $expectedFiles) {
        $found = $entries | Where-Object { $_ -like "*$expected*" }
        if ($found) {
            Write-Host "  ✓ Found: $expected" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Missing: $expected" -ForegroundColor Red
            $allFound = $false
        }
    }
    
    if ($allFound) {
        Write-Host "✓ Backup contents verified" -ForegroundColor Green
    } else {
        Write-Host "✗ Some files missing from backup" -ForegroundColor Red
    }
    Write-Host ""

    # TEST 3: Restore Backup
    Write-Host "[TEST 3] Restoring backup..." -ForegroundColor Cyan
    $restoreResult = Restore-Backup -BackupFilePath $backupResult.BackupPath -RestoreDestination $restoreDir -Verbose
    
    if ($restoreResult -and $restoreResult.Success) {
        Write-Host "✓ Restore completed successfully" -ForegroundColor Green
        Write-Host "  Files restored: $($restoreResult.FilesRestored)" -ForegroundColor Gray
        if ($restoreResult.Sources) {
            Write-Host "  Original sources: $($restoreResult.Sources -join ', ')" -ForegroundColor Gray
        }
    } else {
        Write-Host "✗ Restore failed" -ForegroundColor Red
    }
    Write-Host ""

    # TEST 4: Verify restored files
    Write-Host "[TEST 4] Verifying restored files..." -ForegroundColor Cyan
    $restoredFile1 = Get-ChildItem -Path $restoreDir -Recurse -Filter "file1.txt" | Select-Object -First 1
    $restoredFile2 = Get-ChildItem -Path $restoreDir -Recurse -Filter "file2.txt" | Select-Object -First 1
    $restoredNested = Get-ChildItem -Path $restoreDir -Recurse -Filter "nested.txt" | Select-Object -First 1
    
    if ($restoredFile1 -and $restoredFile2 -and $restoredNested) {
        Write-Host "✓ All expected files restored" -ForegroundColor Green
        
        # Verify content
        $content1 = Get-Content $restoredFile1.FullName -Raw
        if ($content1 -like "*Test content 1*") {
            Write-Host "  ✓ File content verified" -ForegroundColor Green
        } else {
            Write-Host "  ✗ File content mismatch" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Not all files were restored" -ForegroundColor Red
    }
    Write-Host ""

    # TEST 5: List Backups
    Write-Host "[TEST 5] Listing backups..." -ForegroundColor Cyan
    $backupList = Remove-Backup -BackupDestination $backupDir -ListOnly
    
    if ($backupList -and $backupList.Count -gt 0) {
        Write-Host "✓ Found $($backupList.Count) backup(s)" -ForegroundColor Green
        $backupList | Format-Table Index, Name, Size, Created -AutoSize
    } else {
        Write-Host "✗ No backups listed" -ForegroundColor Red
    }
    Write-Host ""

    # TEST 6: Remove Backup (with confirmation bypass)
    Write-Host "[TEST 6] Removing backup..." -ForegroundColor Cyan
    $removeResult = Remove-Backup -BackupFilePath $backupResult.BackupPath
    
    if ($removeResult -and $removeResult.Status -eq 'Removed') {
        Write-Host "✓ Backup removed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Backup removal failed" -ForegroundColor Red
    }
    Write-Host ""

    # TEST 7: Verify backup is gone
    Write-Host "[TEST 7] Verifying backup deletion..." -ForegroundColor Cyan
    if (-not (Test-Path $backupResult.BackupPath)) {
        Write-Host "✓ Backup file deleted" -ForegroundColor Green
    } else {
        Write-Host "✗ Backup file still exists" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  ALL TESTS COMPLETED" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

} catch {
    Write-Host "`n✗ TEST FAILED WITH ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
} finally {
    # Cleanup
    Write-Host "[CLEANUP] Removing test directories..." -ForegroundColor Yellow
    if (Test-Path $testRoot) {
        Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Cleanup complete" -ForegroundColor Green
    }
}

Write-Host "`nTest completed. Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
