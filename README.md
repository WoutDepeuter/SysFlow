
# SysFlow - PowerShell Automation Platform

**SysFlow** is a modular automation platform designed to simplify the daily tasks of system administrators. It centralizes monitoring, backup management and software installation into one user-friendly console interface (TUI), written entirely in PowerShell.

---

## 1. Project goal
The goal of this project is to build a **Minimum Viable Product (MVP)** for local system automation. Instead of using separate commands or GUI tools, SysFlow provides a single entry point for:
* **Monitoring:** Real-time insight into system resources (CPU, RAM, storage) and processes.
* **Backups:** Safely archiving files into compressed archives with simple versioning.
* **Software management:** Installing and updating applications via package managers without manual downloads.
* **Reporting:** Automatically logging actions and exporting system data to CSV and HTML for audit purposes.

This project was created as part of the **System Automation & Scripting** course (3rd year).

## 2. Requirements
To run SysFlow correctly, the target system should meet the following requirements:

* **Operating system:** Windows 10 or Windows 11.
* **PowerShell version:** 5.1 or higher (PowerShell 7+ recommended).
* **Privileges:** Run the script as **Administrator** (required for software installs and CIM/WMI queries).
* **Dependencies:**
    * Internet connection (for software management).
    * Installed package managers: **Winget** (default on modern Windows) and/or **Chocolatey**.

## 3. Installation
SysFlow is a "portable" script application and does not require a complex installer.

1.  **Download:** Clone this repository or download the source as a ZIP file to a local folder (for example `C:\Scripts\SysFlow`).
2.  **Unblock:** Because scripts come from the internet, you may need to unblock them. Open PowerShell as Administrator and run:
    ```powershell
    Get-ChildItem -Path "C:\Scripts\SysFlow" -Recurse | Unblock-File
    ```
3.  **Execution policy:** Allow scripts to run on your system:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

## 4. Configuration
Configuration is stored in `SysFlow/config.psd1`. You can edit this file manually or change settings via the in-app Settings menu (Option 5).

Key settings in `config.psd1`:
* **Paths:**
    * `DefaultBackupDestination`: Default folder where backups are stored.
    * `DefaultReportPath`: Where CSV/HTML reports are generated.
    * `LogPath`: Location of the technical log file.
* **Thresholds:**
    * `CPUThreshold`, `RAMThreshold`: Percentage at which a warning is raised (typically 50–70%).
    * `ProcessMemoryThreshold`: Warning when a process uses more than X MB of memory.

## 5. How to use it
1. Open PowerShell as **Administrator**.
2. Navigate to the `SysFlow` folder:
     ```powershell
     cd "C:\Users\...\SysFlow\SysFlow"
     ```
3. Start the application via the main script (this automatically imports `SysFlowModule.psm1`):
     ```powershell
     .\Start-SysFlow.ps1
     ```
4. Use the numeric menu to navigate:
     * `1`: **System Monitoring**  
         Display CPU/RAM/Storage/Uptime/Process statistics. Results are shown in a table and – depending on configuration – also written to `History.csv` and the HTML report `Report.html` in the configured `DefaultReportPath`.
     * `2`: **Backup Management**  
         Create ZIP backups (with manifest) of one or more folders, restore backups (to a target folder or original paths via the manifest), and list or remove existing backups.
     * `3`: **Software Management**  
         Retrieve the list of installed software, install new packages or update/uninstall existing packages via **Winget** or **Chocolatey**. The default package manager is determined by `DefaultPackageManager` in `config.psd1`.
     * `4`: **Reporting**  
         Reserved for future reporting extensions. Most reporting currently happens automatically from monitoring and backup actions (HTML + CSV export).
     * `5`: **Settings**  
         Change paths (`DefaultBackupDestination`, `DefaultBackupSource`, `DefaultReportPath`), thresholds (CPU/RAM/Storage/ProcessMemory) and the default package manager. Changes are written back to `config.psd1`.
     * `Q`: Exit SysFlow.

**Logs & reports:**
- Technical logs: in the folder configured by `LogPath` (by default `SysFlow/Logs/SysFlow.log`).
- CSV/HTML reports: in the folder configured by `DefaultReportPath` (by default `SysFlow/Reports/`, including `History.csv` and `Report.html`).

## 6. Architecture & structure
The project follows a modular structure to make maintenance and extension by others easy.

### Folder structure
```text
SysFlow-Software-module/
├── README.md               <-- This file
├── SysFlow/
│   ├── Start-SysFlow.ps1   <-- CONTROLLER: Main menu and flow logic
│   ├── config.psd1         <-- CONFIG: Hashtable with settings
│   ├── Logs/               <-- DATA: Generated log files
│   ├── Modules/            <-- LOGIC: All domain functionality
│   │   ├── SysFlowModule.psm1  (Main module that exports all functions)
│   │   ├── BackupModule/       (New-Backup, Restore-Backup, Remove-Backup)
│   │   ├── MonitorModule/      (Get-CPUStats, Get-RamStats, etc.)
│   │   ├── ReportingModule/    (Write-SysFlowLog, Export-StatToHtml)
│   │   └── SoftwareModule/     (Install-Software, Get-SoftwareList)
│   └── Tests/              <-- QUALITY: Pester unit tests

```

### Technical choices

* **Controller script:** `Start-SysFlow.ps1` contains no heavy logic, but imports the main module `Modules/SysFlowModule.psm1` and calls functions from there. This keeps the interface separated from the core logic.
* **Modules:** Instead of multiple separate module files there is now one central module `SysFlowModule.psm1` which dot-sources the functions from `BackupModule`, `MonitorModule`, `ReportingModule` and `SoftwareModule` and exports them as a single API.
* **Object-oriented data:** Functions (such as `Get-CPUStats`) return `PSCustomObject` instances instead of plain text. This makes it easy to both display data (`Format-Table`) and export it (`Export-Csv`).
* **Error handling:** Critical actions (such as installs or file operations) are wrapped in `try/catch` blocks with logging via `Write-SysFlowLog`.

## 7. References

This project is an academic assignment. The following sources were consulted and used:

### Course material

* Course **System Automation & Scripting** (Erasmus University College Brussels, 2024–2025).
* PowerPoint slides and lecture notes about PowerShell functions, modules and CIM/WMI classes.

### Documentation

* **Microsoft Learn:** PowerShell documentation (e.g. `Get-CimInstance`, `Compress-Archive`).
* **Package managers:** Official documentation of [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) and [Chocolatey](https://docs.chocolatey.org/).

### Artificial Intelligence (AI)

Generative AI (Google Gemini & OpenAI ChatGPT) was used for:

* **Code generation:** Helping set up the skeleton structure of modules (e.g. `ReportingModule`).
* **Debugging:** Analysing error messages for the `Restore-Backup` manifest logic and improving the backup function (e.g. supporting backups larger than 2 GB).
* **Documentation:** Generating templates for `.SYNOPSIS` help blocks and parts of this README.
* *Note:* All AI-generated code was manually reviewed, tested and adapted to the specific requirements of this project.

### Online sources

* StackOverflow (specific syntax questions about hashtables and arrays).
* GitHub (inspiration for folder structures of PowerShell modules).

---

*Author: Wout De Peuter*  
*Date: January 2025*
