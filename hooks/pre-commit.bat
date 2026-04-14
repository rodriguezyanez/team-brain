@echo off
REM =============================================================
REM Guardian Angel — Hook pre-commit KLAP BYSF (Windows CMD)
REM Para ejecucion manual. El hook real (.git/hooks/pre-commit)
REM usa pre-commit.sh via Git Bash.
REM Bypass urgente: git commit --no-verify
REM =============================================================
setlocal EnableDelayedExpansion

echo.
echo [GGA] Guardian Angel revisando el commit...
echo.

REM -- Verificar claude CLI --
where claude >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [GGA] WARN: Claude CLI no encontrado. Salteando revision.
    echo       Instala con: npm install -g @anthropic-ai/claude-code
    exit /b 0
)

REM -- Verificar review-prompt.md --
set SCRIPT_DIR=%~dp0
if not exist "%SCRIPT_DIR%review-prompt.md" (
    echo [GGA] WARN: review-prompt.md no encontrado en %SCRIPT_DIR%
    echo       Salteando revision.
    exit /b 0
)

REM -- Obtener diff staged --
git diff --cached --diff-filter=ACMR -- "*.java" "*.kt" > "%TEMP%\gga_diff.txt" 2>nul
for %%A in ("%TEMP%\gga_diff.txt") do if %%~zA equ 0 (
    echo [GGA] Sin cambios Java/Kotlin staged. Commit permitido.
    del "%TEMP%\gga_diff.txt" >nul 2>&1
    exit /b 0
)

REM -- Construir prompt --
copy /y "%SCRIPT_DIR%review-prompt.md" "%TEMP%\gga_prompt.txt" >nul
echo. >> "%TEMP%\gga_prompt.txt"
echo ## Diff a revisar >> "%TEMP%\gga_prompt.txt"
echo ```diff >> "%TEMP%\gga_prompt.txt"
type "%TEMP%\gga_diff.txt" >> "%TEMP%\gga_prompt.txt"
echo ``` >> "%TEMP%\gga_prompt.txt"

REM -- Llamar a Claude --
claude --print < "%TEMP%\gga_prompt.txt" > "%TEMP%\gga_result.txt" 2>&1

REM -- Parsear resultado --
findstr /C:"GUARDIAN_ANGEL_RESULT=FAIL" "%TEMP%\gga_result.txt" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo  GGA Guardian Angel bloqueo el commit - violaciones encontradas
    echo ============================================================
    type "%TEMP%\gga_result.txt"
    echo.
    echo Corregi las violaciones y volve a hacer commit.
    echo Commit urgente sin revision: git commit --no-verify
    del "%TEMP%\gga_diff.txt" "%TEMP%\gga_prompt.txt" "%TEMP%\gga_result.txt" >nul 2>&1
    exit /b 1
)

echo.
echo [GGA] Commit aprobado.
type "%TEMP%\gga_result.txt"
del "%TEMP%\gga_diff.txt" "%TEMP%\gga_prompt.txt" "%TEMP%\gga_result.txt" >nul 2>&1
exit /b 0
