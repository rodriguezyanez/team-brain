@echo off
REM =============================================================
REM brain-sync.bat — Sincroniza memorias pendientes con Neo4j
REM
REM Uso:
REM   brain-sync.bat
REM
REM Delega en brain-sync.ps1 (PowerShell).
REM Requiere PowerShell 5+ (incluido en Windows 10/11).
REM =============================================================

powershell.exe -ExecutionPolicy Bypass -File "%~dp0brain-sync.ps1" %*
