
***

# SysFlow - PowerShell Automation Platform

Een PowerShell-gedreven automatiseringsplatform dat lokale IT-beheertaken vereenvoudigt en automatiseert.

## Over dit Project

Dit project is ontwikkeld in het kader van de module **System Automation & Scripting** aan de **Erasmus Hogeschool Brussel**.

Het doel van dit project is het ontwikkelen van een centrale tool ("Minimum Viable Product") waarmee systeembeheerders veelvoorkomende infrastructuurtaken efficiënt kunnen uitvoeren, zonder nood aan manuele interventie. De tool automatiseert systeemmonitoring, softwarebeheer en back-upbeheer binnen één gebruiksvriendelijke PowerShell-interface, volledig onafhankelijk van cloudplatformen.

## Functionaliteiten

De tool is opgebouwd uit afzonderlijke modules die samenkomen in één centraal script:

* **Systeemmonitoring:** Controle en logging van CPU-, RAM- en schijfgebruik, uptime en algemene systeemstatus.
* **Automatische Back-ups:** Selectie, compressie, logging en herstelprocedures van geselecteerde mappen.
* **Softwarebeheer:** Integratie met package managers (Chocolatey/Winget) voor installatie, verwijdering en updates van software.
* **Rapportgeneratie:** Automatische generatie van HTML- of CSV-rapporten met een overzicht van de uitgevoerde acties en systeemstatus.
* **Modulair Systeem:** Elke functionaliteit is ondergebracht in een eigen module met specifieke `Get-Help` documentatie.

## Technologie Stack

* **Taal:** Windows PowerShell (5.1 of hoger)
* **Package Management:** Chocolatey / Winget
* **Automatisering:** Windows Task Scheduler
* **Testing:** Pester (Unit Testing framework)
