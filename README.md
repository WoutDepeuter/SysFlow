
# SysFlow - PowerShell Automation Platform

**SysFlow** is a modular automation platform designed to simplify the daily tasks of system administrators. This tool centralizes system monitoring, backup management, and software installation into a single, user-friendly console interface (TUI), entirely written in PowerShell.

---

## 1. Project Goal
The goal of this project is to develop a **"Minimum Viable Product" (MVP)** for local system automation. Instead of using disparate commands or GUIs, SysFlow offers a single central point for:
* **Monitoring:** Real-time insights into system resources (CPU, RAM, Storage, Uptime) and processes.
* **Backups:** Securing files into compressed archives with versioning support (supporting large files >2GB via .NET).
* **Software Management:** Installing, updating, and removing applications via package managers (Winget/Chocolatey) without manual downloads.
* **Reporting:** Automatically logging actions and exporting system data to CSV and HTML for audit purposes.
* **Automation:** Scheduling daily maintenance tasks via the Windows Task Scheduler.

This project was developed as part of the **System Automation & Scripting** module (Year 3).

## 2. Requirements
To function correctly, the target system must meet the following requirements:

* **Operating System:** Windows 10 or Windows 11.
* **PowerShell Version:** 5.1 or higher (PowerShell 7+ recommended).
* **Permissions:** The script must be run as **Administrator** (required for software installations, Task Scheduler registration, and CIM/WMI queries).
* **Dependencies:**
    * Active internet connection (for software management).
    * Installed package managers: **Winget** (standard in modern Windows) and/or **Chocolatey**.

## 3. Installation
SysFlow is a "portable" script application and requires no complex installation.

1.  **Download:** Clone this repository or download the source code as a ZIP file to a local folder (e.g., `C:\Scripts\SysFlow`).
2.  **Unblock:** Since scripts downloaded from the internet may be blocked by Windows security, open PowerShell as Administrator and run:
    ```powershell
    Get-ChildItem -Path "C:\Scripts\SysFlow" -Recurse | Unblock-File
    ```
3.  **Execution Policy:** Ensure that scripts are allowed to run on your system:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

## 4. Configuration
Configuration is managed in the `SysFlow/config.psd1` file. You can edit this file manually or change settings via the application menu (Option 5).

Key settings in `config.psd1`:
* **Paths:**
    * `DefaultBackupSource`: Default folder to back up (used for automated tasks).
    * `DefaultBackupDestination`: Where backups are saved by default.
    * `DefaultReportPath`: Where CSV/HTML reports are generated.
    * `LogPath`: Location of the technical log file.
* **Thresholds:**
    * `CPUThreshold`, `RAMThreshold`: Percentage at which a warning is triggered (default 70%).
    * `ProcessMemoryThreshold`: Warning if a process uses more than X MB memory.

## 5. Usage

### Interactive Mode
1.  Open PowerShell as **Administrator**.
2.  Navigate to the `SysFlow` folder.
3.  Start the main controller script:
    ```powershell
    .\Start-SysFlow.ps1
    ```
4.  Use the numeric menu to navigate:
    * `1`: **System Monitoring** (View live stats, export to CSV/HTML).
    * `2`: **Backup Management** (Create/Restore/Remove backups).
    * `3`: **Software Management** (Install/Update software via Winget/Choco).
    * `4`: **Reporting** (Generate unified HTML reports).
    * `5`: **Settings** (Adjust configuration paths and thresholds live).

### Automated Mode (Task Scheduler)
You can schedule SysFlow to perform daily backups automatically.
1.  Start `Start-SysFlow.ps1`.
2.  Go to **Backup Management (2)** -> **Schedule Daily Backup (5)**.
3.  Enter the desired time (e.g., `03:00`).
4.  The tool will register a Windows Task that runs `Run-DailyBackup.ps1` in the background every day using the settings defined in `config.psd1`.

## 6. Architecture & Structure
The project follows a strict modular structure to facilitate maintenance and portability.

### Folder Structure
```text
SysFlow/
├── Start-SysFlow.ps1           <-- CONTROLLER: Interactive menu, loads the module
├── Register-DailyBackupTask.ps1 <-- AUTOMATION: Script to register scheduled tasks
├── Run-DailyBackup.ps1         <-- AUTOMATION: Headless script for background tasks
├── config.psd1                 <-- CONFIG: Hashtable with user settings
├── Logs/                       <-- DATA: Generated log files
├── Reports/                    <-- DATA: Generated HTML/CSV reports
├── Modules/                    <-- LOGIC: The core functionality
│   ├── SysFlowModule.psm1      <-- UNIFIED MODULE: Loads all sub-functions
│   ├── BackupModule/           (New-Backup, Restore-Backup, Remove-Backup)
│   ├── MonitorModule/          (Get-CPUStats, Get-RamStats, etc.)
│   ├── ReportingModule/        (Write-SysFlowLog, Export-StatToHtml)
│   └── SoftwareModule/         (Install-Software, Get-SoftwareList)
└── Tests/                      <-- QUALITY: Pester unit tests

```

### Technical Choices

* **Unified Module:** All functions are aggregated into `SysFlowModule.psm1`. This allows the entire toolset to be imported via `Import-Module SysFlowModule.psm1`, meeting the "single module" requirement.
* **Controller Script:** `Start-SysFlow.ps1` contains no heavy logic but acts as a UI layer that calls functions from the module.
* **Object-Oriented:** Functions return `PSCustomObjects` instead of plain text. This allows data to be used flexibly (e.g., displayed in a table AND exported to CSV simultaneously).
* **Robustness:** * Backups use `.NET System.IO.Compression` to support files larger than 2GB (bypassing `Compress-Archive` limitations).
* Software management auto-detects installed package managers.



## 7. Sources & References

This project is an academic work. The following sources were consulted and utilized during development:

### Course Material

* Course **System Automation & Scripting** (Erasmus Brussels University of Applied Sciences and Arts, 2024-2025).
* Lectures on PowerShell Advanced Functions, Modules, and CIM/WMI classes.

### Documentation

* **Microsoft Learn:** PowerShell documentation (e.g., `Get-CimInstance`, `.NET compression classes`, `Register-ScheduledTask`).
* **Package Managers:** Official documentation for [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) and [Chocolatey](https://docs.chocolatey.org/).

### Artificial Intelligence (AI)

Generative AI (Google Gemini & OpenAI ChatGPT) was used for:

* **Module Consolidation:** Assisting in merging separate script files into a single unified module (`SysFlowModule.psm1`) to meet project architecture requirements.
* **Code Scaffolding:** Generating the initial structure of the `ReportingModule`.
* **Debugging:** Troubleshooting the `Stream was too long` error in `Compress-Archive` and providing the .NET replacement code.
* **Documentation:** Assisting in generating Comment-Based Help blocks and translating this README.
* *Note:* All AI-generated code has been manually reviewed, tested, and adapted to the specific requirements of this project.

### Online Resources

* StackOverflow (Specific syntax questions regarding hashtables and arrays).
* GitHub (Inspiration for PowerShell module best practices).

---

*Author: Wout De Peuter*
*Date: January 2026*

```

```
