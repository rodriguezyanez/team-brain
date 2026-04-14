@echo off
REM =============================================================
REM install-hooks.bat — Instala Guardian Angel en un proyecto
REM
REM Uso:
REM   install-hooks.bat                       <- instala en directorio actual
REM   install-hooks.bat C:\ruta\al\proyecto   <- instala en proyecto indicado
REM
REM Para desinstalar:
REM   del C:\ruta\proyecto\.git\hooks\pre-commit
REM   del C:\ruta\proyecto\.git\hooks\review-prompt.md
REM =============================================================
setlocal EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
set HOOKS_SRC=%SCRIPT_DIR%hooks

REM -- Determinar proyecto destino --
if "%~1"=="" (
    set PROJECT_DIR=%CD%
) else (
    set PROJECT_DIR=%~1
)

echo.
echo === Instalando Guardian Angel KLAP BYSF ===
echo.

REM -- Verificar repo git --
if not exist "%PROJECT_DIR%\.git" (
    echo [ERROR] No se encontro .git en: %PROJECT_DIR%
    echo         Indica el directorio raiz del proyecto:
    echo         install-hooks.bat C:\ruta\mi-servicio
    exit /b 1
)

set GIT_HOOKS=%PROJECT_DIR%\.git\hooks

REM -- Verificar archivos fuente --
if not exist "%HOOKS_SRC%\pre-commit.sh" (
    echo [ERROR] hooks\pre-commit.sh no encontrado en %HOOKS_SRC%
    exit /b 1
)
if not exist "%HOOKS_SRC%\review-prompt.md" (
    echo [ERROR] hooks\review-prompt.md no encontrado en %HOOKS_SRC%
    exit /b 1
)

REM -- Crear directorio hooks si no existe --
if not exist "%GIT_HOOKS%" mkdir "%GIT_HOOKS%"

REM -- Backup si ya existe pre-commit --
if exist "%GIT_HOOKS%\pre-commit" (
    copy /y "%GIT_HOOKS%\pre-commit" "%GIT_HOOKS%\pre-commit.bak" >nul
    echo [INFO] Backup creado: .git\hooks\pre-commit.bak
)

REM -- Copiar hook y prompt --
copy /y "%HOOKS_SRC%\pre-commit.sh"    "%GIT_HOOKS%\pre-commit"       >nul
copy /y "%HOOKS_SRC%\review-prompt.md" "%GIT_HOOKS%\review-prompt.md" >nul

echo [OK] Hook instalado en: %GIT_HOOKS%\pre-commit
echo [OK] Prompt copiado en: %GIT_HOOKS%\review-prompt.md
echo.
echo === Guardian Angel activo en: %PROJECT_DIR% ===
echo.
echo   Cada commit en archivos .java/.kt sera revisado.
echo   Commit urgente sin revision: git commit --no-verify
echo   Desinstalar: del "%GIT_HOOKS%\pre-commit"
echo.

endlocal
exit /b 0
