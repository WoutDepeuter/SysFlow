
function Get-ProcessStats {
    <#
    .SYNOPSIS
        Retrieves process statistics and alerts on high memory usage.

    .DESCRIPTION
        The Get-ProcessStats function gathers information about running processes including name,
        process ID, owner, and memory usage in MB. It alerts when processes exceed the specified
        memory threshold.

    .PARAMETER threshold
        Memory usage threshold in MB for triggering an alert.
        Default value is 80. Processes using more memory will trigger a warning.

    .PARAMETER pageSize
        Number of processes to display per page.
        Default value is 10.

    .PARAMETER Interactive
        When specified, enables an interactive menu to scroll through pages using keyboard navigation.
        Use N (next), P (previous), G (go to page), or Q (quit).

    .EXAMPLE
        Get-ProcessStats
        
        Retrieves all processes with default threshold of 80 MB, paginated with 10 items per page.

    .EXAMPLE
        Get-ProcessStats -Interactive
        
        Opens an interactive scrollable menu to browse through process pages.

    .EXAMPLE
        Get-ProcessStats -Interactive -threshold 500 -pageSize 20
        
        Opens interactive menu with 500 MB threshold, showing 20 items per page.

    .EXAMPLE
        Get-ProcessStats -threshold 500 -pageSize 20
        
        Retrieves processes with 500 MB threshold, showing 20 items per page on page 1.

    .OUTPUTS
        PSCustomObject array with properties:
        - Name: Process name
        - ProcessId: Process ID
        - Owner: Process owner/user
        - MemoryUsageMB: Memory usage in MB
        - CurrentPage: Current page number (added dynamically)
        - TotalPages: Total number of pages (added dynamically)
        - PageSize: Items per page (added dynamically)
        - TotalItems: Total number of processes (added dynamically)

    .NOTES
        Author: SysFlow
        Version: 1.0
        Requires: PowerShell with CIM access
    #>
    [CmdletBinding()]
    param(
        [int]$threshold = 80,
        [int]$pageSize = 10,
        [switch]$Interactive
    )

    # Get process information
    $processes = Get-CimInstance -ClassName Win32_Process | Select-Object Name, ProcessId, @{Name="Owner";Expression={($_.GetOwner().User)}}, @{Name="MemoryUsageMB";Expression={[math]::Round($_.WorkingSetSize / 1MB, 2)}}

    # Filter processes exceeding memory usage threshold
    $highMemoryProcesses = $processes | Where-Object { $_.MemoryUsageMB -ge $threshold }

    if ($highMemoryProcesses) {
        Write-Host "ALERT: The following processes are using more than $threshold MB of memory:" -ForegroundColor Red
        $highMemoryProcesses | Format-Table -AutoSize
    } else {
        Write-Host "All processes are within acceptable memory usage limits." -ForegroundColor Green
    }

    # Paginate results
    $totalProcesses = @($processes).Count
    $totalPages = [math]::Ceiling($totalProcesses / $pageSize)
    $pageNumber = 1

    # Interactive menu
    if ($Interactive) {
        $continue = $true
        while ($continue) {
            Clear-Host
            
            # Validate page number
            if ($pageNumber -lt 1) { $pageNumber = 1 }
            if ($pageNumber -gt $totalPages -and $totalPages -gt 0) { $pageNumber = $totalPages }

            # Calculate skip count
            $skipCount = ($pageNumber - 1) * $pageSize

            # Get paginated results
            $paginatedProcesses = $processes | Select-Object -Skip $skipCount -First $pageSize

            # Display pagination info
            Write-Host "PROCESS STATS - Interactive Mode" -ForegroundColor Yellow -BackgroundColor Black
            Write-Host "═" * 80 -ForegroundColor Cyan
            Write-Host "Page $pageNumber of $totalPages (Items $($skipCount + 1)-$($skipCount + @($paginatedProcesses).Count) of $totalProcesses) | Threshold: $threshold MB" -ForegroundColor Cyan
            Write-Host "─" * 80 -ForegroundColor Cyan
            
            $paginatedProcesses | Format-Table -AutoSize

            # Display high memory alerts on current page
            $highMemoryOnPage = $paginatedProcesses | Where-Object { $_.MemoryUsageMB -ge $threshold }
            if ($highMemoryOnPage) {
                Write-Host "⚠ WARNING: Processes on this page using $threshold MB or more:" -ForegroundColor Red
                $highMemoryOnPage | Format-Table Name, MemoryUsageMB -AutoSize
            } else {
                Write-Host "✓ No processes on this page exceed the $threshold MB threshold" -ForegroundColor Green
            }

            # Display menu
            Write-Host "═" * 80 -ForegroundColor Cyan
            Write-Host "[N]ext  [P]revious  [G]o to page  [Q]uit" -ForegroundColor Yellow
            $choice = Read-Host "Select option"

            switch ($choice.ToUpper()) {
                'N' {
                    if ($pageNumber -lt $totalPages) {
                        $pageNumber++
                    } else {
                        Write-Host "Already on last page!" -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
                'P' {
                    if ($pageNumber -gt 1) {
                        $pageNumber--
                    } else {
                        Write-Host "Already on first page!" -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
                'G' {
                    $targetPage = Read-Host "Enter page number (1-$totalPages)"
                    if ([int]::TryParse($targetPage, [ref]$null)) {
                        $targetPage = [int]$targetPage
                        if ($targetPage -ge 1 -and $targetPage -le $totalPages) {
                            $pageNumber = $targetPage
                        } else {
                            Write-Host "Invalid page number! Enter between 1 and $totalPages" -ForegroundColor Red
                            Start-Sleep -Seconds 2
                        }
                    } else {
                        Write-Host "Invalid input! Enter a number." -ForegroundColor Red
                        Start-Sleep -Seconds 2
                    }
                }
                'Q' {
                    $continue = $false
                }
                default {
                    Write-Host "Invalid option! Use N, P, G, or Q" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        Write-Host "Exiting process stats viewer..." -ForegroundColor Green
        return
    }

    # Non-interactive mode: show first page
    $pageNumber = 1
    $skipCount = 0
    $paginatedProcesses = $processes | Select-Object -Skip $skipCount -First $pageSize

    # Display pagination info
    Write-Host "`nDisplaying page $pageNumber of $totalPages (Items $($skipCount + 1)-$($skipCount + @($paginatedProcesses).Count) of $totalProcesses):" -ForegroundColor Cyan
    $paginatedProcesses | Format-Table -AutoSize

    # Add pagination info as note properties to each process object
    foreach ($process in $paginatedProcesses) {
        $process | Add-Member -NotePropertyName CurrentPage -NotePropertyValue $pageNumber -Force
        $process | Add-Member -NotePropertyName TotalPages -NotePropertyValue $totalPages -Force
        $process | Add-Member -NotePropertyName PageSize -NotePropertyValue $pageSize -Force
        $process | Add-Member -NotePropertyName TotalItems -NotePropertyValue $totalProcesses -Force
    }

    return $paginatedProcesses
}