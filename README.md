
# SysFlow - PowerShell Automation Platform

**SysFlow** is een modulair automatiseringsplatform ontwikkeld om dagelijkse taken van systeembeheerders te vereenvoudigen. Deze tool centraliseert monitoring, back-upbeheer en software-installaties in één gebruiksvriendelijke console-interface (TUI), volledig geschreven in PowerShell.

---

## 1. Het doel van het project
Het doel van dit project is het ontwikkelen van een "Minimum Viable Product" (MVP) voor lokale systeemautomatisering. In plaats van verschillende losse commando's of GUI's te gebruiken, biedt SysFlow één centraal punt voor:
* **Monitoring:** Real-time inzicht in systeembronnen (CPU, RAM, Opslag) en processen.
* **Back-ups:** Het veiligstellen van bestanden naar gecomprimeerde archieven met versiebeheer.
* **Softwarebeheer:** Het installeren en updaten van applicaties via package managers zonder handmatige downloads.
* **Rapportage:** Het automatisch loggen van acties en exporteren van systeemdata naar CSV en HTML voor audit-doeleinden.

Dit project is ontwikkeld in het kader van de module **System Automation & Scripting** (3e jaar).

## 2. Requirements (Vereisten)
Om SysFlow correct te laten functioneren, moet het doelsysteem voldoen aan de volgende eisen:

* **Besturingssysteem:** Windows 10 of Windows 11.
* **PowerShell Versie:** 5.1 of hoger (aanbevolen: PowerShell 7+).
* **Rechten:** Het script moet worden uitgevoerd als **Administrator** (nodig voor software-installaties en CIM/WMI-queries).
* **Afhankelijkheden:**
    * Internetverbinding (voor softwarebeheer).
    * Geïnstalleerde package managers: **Winget** (standaard in moderne Windows) en/of **Chocolatey**.

## 3. Hoe installeer je het?
SysFlow is een "portable" script-applicatie en vereist geen complexe installatie.

1.  **Downloaden:** Clone deze repository of download de broncode als ZIP naar een lokale map (bijv. `C:\Scripts\SysFlow`).
2.  **Deblokkeren:** Omdat scripts van het internet komen, moet je ze mogelijk deblokkeren. Open PowerShell als Administrator en draai:
    ```powershell
    Get-ChildItem -Path "C:\Scripts\SysFlow" -Recurse | Unblock-File
    ```
3.  **Execution Policy:** Zorg dat scripts mogen draaien op je systeem:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

## 4. Hoe configureer je het?
De configuratie wordt beheerd in het bestand `SysFlow/config.psd1`. Je kunt dit bestand handmatig bewerken of instellingen wijzigen via het menu in de applicatie (Optie 5).

Belangrijke instellingen in `config.psd1`:
* **Paden:**
    * `DefaultBackupDestination`: Waar back-ups standaard worden opgeslagen.
    * `DefaultReportPath`: Waar CSV/HTML rapporten worden gegenereerd.
    * `LogPath`: Locatie van het technische logbestand.
* **Drempelwaarden (Thresholds):**
    * `CPUThreshold`, `RAMThreshold`: Percentage waarna een waarschuwing wordt gegeven (standaard 50-70%).
    * `ProcessMemoryThreshold`: Waarschuwing als een proces meer dan X MB geheugen gebruikt.

## 5. Hoe gebruik je het?
1.  Open PowerShell als **Administrator**.
2.  Navigeer naar de map `SysFlow`.
3.  Start het hoofdscript:
    ```powershell
    .\Start-SysFlow.ps1
    ```
4.  Gebruik het numerieke menu om te navigeren:
    * `1`: **System Monitoring** (Bekijk live stats en exporteer naar CSV).
    * `2`: **Backup Management** (Maak of herstel back-ups van mappen).
    * `3`: **Software Management** (Installeer/Update software via Winget/Choco).
    * `4`: **Reporting** (Genereer gecombineerde HTML-rapporten van eerdere scans).
    * `5`: **Settings** (Pas configuratiepaden en drempelwaarden live aan).
    * `Q`: Afsluiten.

**Logbestanden:** Na gebruik kun je logs terugvinden in de map `SysFlow/Logs/` en rapporten in `SysFlow/Reports/`.

## 6. Architectuur & Structuur
Het project volgt een strikte modulaire structuur om onderhoud en uitbreiding door derden te vergemakkelijken.

### Mappenstructuur
```text
SysFlow-Software-module/
├── README.md               <-- Dit bestand
├── SysFlow/
│   ├── Start-SysFlow.ps1   <-- CONTROLLER: Hoofdmenu en flow-logica
│   ├── config.psd1         <-- CONFIG: Hashtable met instellingen
│   ├── Logs/               <-- DATA: Gegenereerde logbestanden
│   ├── Modules/            <-- LOGICA: Alle functionaliteit per domein
│   │   ├── BackupModule/       (New-Backup, Restore-Backup, Remove-Backup)
│   │   ├── MonitorModule/      (Get-CPUStats, Get-RamStats, etc.)
│   │   ├── ReportingModule/    (Write-SysFlowLog, Export-StatToHtml)
│   │   └── SoftwareModule/     (Install-Software, Get-SoftwareList)
│   └── Tests/              <-- KWALITEIT: Pester unit tests

```

### Technische keuzes

* **Controller-script:** `Start-SysFlow.ps1` bevat geen zware logica, maar roept functies aan uit de modules. Dit houdt de interface gescheiden van de code.
* **Object-georiënteerd:** Functies (zoals `Get-CPUStats`) retourneren `PSCustomObjects` in plaats van platte tekst. Hierdoor kan de data zowel getoond (`Format-Table`) als geëxporteerd (`Export-Csv`) worden.
* **Foutafhandeling:** Kritieke acties (zoals installaties of bestandsoperaties) zijn verpakt in `Try/Catch` blokken met logging naar `Write-SysFlowLog`.

## 7. Bronvermelding

Dit project is een academisch werk. Bij de totstandkoming zijn de volgende bronnen geraadpleegd en gebruikt:

### Cursusmateriaal

* Cursus **System Automation & Scripting** (Erasmus Hogeschool Brussel, 2024-2025).
* PowerPoint-slides en lesnotities over PowerShell functies, modules en CIM/WMI-classes.

### Documentatie

* **Microsoft Learn:** PowerShell documentatie (o.a. `Get-CimInstance`, `Compress-Archive`).
* **Package Managers:** Officiële documentatie van [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) en [Chocolatey](https://docs.chocolatey.org/).

### Artificiële Intelligentie (AI)

Er is gebruikgemaakt van Generatieve AI (Google Gemini & OpenAI ChatGPT) voor:

* **Code Generatie:** Hulp bij het opzetten van de skeletstructuur van modules (o.a. `ReportingModule`).
* **Debugging:** Het analyseren van foutmeldingen bij de `Restore-Backup` manifest-logica.
* **Documentatie:** Het genereren van sjablonen voor `.SYNOPSIS` help-blokken in de scripts en delen van deze README.
* *Opmerking:* Alle door AI gegenereerde code is handmatig gereviewd, getest en aangepast aan de specifieke eisen van dit project.

### Online Bronnen

* StackOverflow (Specifieke syntax-vragen over hashtables en arrays).
* GitHub (Inspiratie voor folderstructuren van PowerShell-modules).

---

*Auteur: Wout De Peuter*
*Datum: Januari 2025*

```

```
