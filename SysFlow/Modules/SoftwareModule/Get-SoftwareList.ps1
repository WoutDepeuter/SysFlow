#function to get the list of installed software on a Windows machine
function Get-SoftwareList {
<#
    .SYNOPSIS
        Retrieves a list of installed software on the local machine.

    .DESCRIPTION
        This function queries the Windows registry to gather information about installed software packages.
        It returns a list of software with details such as name, version, publisher, and installation date.

    .EXAMPLE
        Get-SoftwareList
        
        Retrieves the list of all installed software on the local machine.

    .EXAMPLE
        $softwareList = Get-SoftwareList
        $softwareList | Format-Table -AutoSize
        
        Retrieves the list of installed software and formats it in a table for better readability.

    .OUTPUTS
        PSCustomObject with properties:
        - Name: Software name
        - Version: Software version
        - Publisher: Software publisher
        - InstallDate: Date when the software was installed

    .NOTES

     #>
    # Define registry paths to check for installed software
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $softwareList = @()
    foreach ($path in $registryPaths) {
        $installedSoftware = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -ne $null }
        foreach ($software in $installedSoftware) {
            $softwareList += [PSCustomObject]@{
                Name        = $software.DisplayName
                Version     = $software.DisplayVersion
                Publisher   = $software.Publisher
                InstallDate = $software.InstallDate
            }
        }
    }
    return $softwareList
}
