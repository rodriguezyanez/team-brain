@echo off
REM =============================================================
REM export-obsidian.bat — Exporta Neo4j a Obsidian vault (Windows)
REM Delega la ejecucion a export-obsidian.ps1
REM
REM Uso:
REM   export-obsidian.bat
REM
REM Requisito: Neo4j corriendo (brain.bat up)
REM =============================================================
setlocal

echo.
echo [INFO] Iniciando exportacion Neo4j a Obsidian vault...
echo.

where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] PowerShell no encontrado. Instala PowerShell 5.1 o superior.
    exit /b 1
)

if not exist "%~dp0export-obsidian.ps1" (
    echo [ERROR] export-obsidian.ps1 no encontrado en %~dp0
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0export-obsidian.ps1" %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] La exportacion fallo. Revisa los mensajes anteriores.
    exit /b 1
)

endlocal
exit /b 0
