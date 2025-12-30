#function to export statistics to CSV
function Export-StatToCsv {
    <#.SYNOPSIS
        Exports given statistics to a CSV file.
    .DESCRIPTION
        The Export-StatToCsv function takes a collection of statistics and exports them to a specified CSV file.
        It accepts parameters for the statistics data and the output file path.
    .PARAMETER Stats
        The collection of statistics to export.
    .PARAMETER OutputFilePath
        The path to the CSV file where the statistics will be saved.
    .EXAMPLE
        $stats = Get-CPUStats
        Export-StatToCsv -Stats $stats -OutputFilePath "C:\Reports\CPUStats.csv"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Stats,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFilePath
    )
    try {
        $Stats | Export-Csv -Path $OutputFilePath -NoTypeInformation -Force
        Write-Output "Statistics exported successfully to $OutputFilePath"
    }
    catch {
        Write-Error "Failed to export statistics: $_"
    }
}

# End of Export-StatToCsv function
