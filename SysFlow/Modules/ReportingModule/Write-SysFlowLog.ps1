#function to write SysFlow log entries
function Write-SysFlowLog {
    <#
    .SYNOPSIS
        Writes log entries for SysFlow operations.
    .DESCRIPTION
        The Write-SysFlowLog function creates log entries for various SysFlow operations.
        It accepts parameters for log level, message, and optional details.
        Logs can be written to a specified log file or displayed in the console.
    .PARAMETER LogLevel
        The severity level of the log entry (e.g., Info, Warning, Error).
    .PARAMETER Message
        The main log message to record.
    .PARAMETER Details
        Optional additional details to include in the log entry.
    .PARAMETER LogFilePath
        Optional path to a log file where the entry will be written.
        If not specified, the log will be output to the console.
    .EXAMPLE
        Write-SysFlowLog -LogLevel "Info" -Message "SysFlow started successfully."
        
        Writes an informational log entry to the console.
    .EXAMPLE
        Write-SysFlowLog -LogLevel "Error" -Message "Failed to connect to database." -Details "Connection timeout." -LogFilePath "C:\Logs\SysFlow.log"
        
        Writes an error log entry with details to the specified log file.
    .OUTPUTS
        None.
    #>
    param(
        