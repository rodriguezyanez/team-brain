@echo off
REM =============================================================
REM install-skills.bat — Instala skill files en Claude Code
REM Copia skills/*.md a %USERPROFILE%\.claude\skills\
REM =============================================================
setlocal enabledelayedexpansion

set "SKILLS_SRC=%~dp0..\skills"
set "SKILLS_DEST=%USERPROFILE%\.claude\skills"
set "EXPECTED=11"
set "COUNT=0"

echo.
echo [INFO] Team Brain — Instalador de Skills para Claude Code
echo [INFO] Origen : %SKILLS_SRC%
echo [INFO] Destino: %SKILLS_DEST%
echo.

REM -----------------------------------------------------------
:CHECK_SOURCE
REM -----------------------------------------------------------
if not exist "%SKILLS_SRC%\" (
    echo [ERROR] No se encontro la carpeta skills\ en el directorio actual.
    echo [ERROR] Ejecuta este script desde la raiz del proyecto team-brain.
    exit /b 1
)
echo [OK] Carpeta skills\ encontrada.

REM -----------------------------------------------------------
:CREATE_DEST
REM -----------------------------------------------------------
if not exist "%SKILLS_DEST%\" (
    echo [WARN] El directorio destino no existe. Creandolo...
    mkdir "%SKILLS_DEST%"
    if errorlevel 1 (
        echo [ERROR] No se pudo crear %SKILLS_DEST%
        exit /b 1
    )
    echo [OK] Directorio creado: %SKILLS_DEST%
) else (
    echo [OK] Directorio destino ya existe.
)

REM -----------------------------------------------------------
:COPY_FILES
REM -----------------------------------------------------------
echo.
echo [INFO] Copiando archivos...

call :DO_COPY "kafka-config.md"
call :DO_COPY "kafka-listener.md"
call :DO_COPY "processor.md"
call :DO_COPY "repository.md"
call :DO_COPY "webclient.md"
call :DO_COPY "exceptions.md"
call :DO_COPY "testing.md"
call :DO_COPY "openapi.md"
call :DO_COPY "skill-registry.md"
call :DO_COPY "sdd-microservice.md"
call :DO_COPY "sdd-checklist.md"

REM -----------------------------------------------------------
:SUMMARY
REM -----------------------------------------------------------
echo.
echo =============================================================
echo  RESUMEN DE INSTALACION
echo =============================================================
echo  Destino : %SKILLS_DEST%
echo  Copiados: %COUNT% / %EXPECTED% archivos
echo.
if %COUNT% == %EXPECTED% (
    echo [OK] Todos los skills instalados correctamente.
) else (
    echo [WARN] Solo se copiaron %COUNT% de %EXPECTED% archivos. Revisa los errores arriba.
)
echo.
echo [INFO] Archivos instalados en %SKILLS_DEST%:
for %%f in ("%SKILLS_DEST%\*.md") do echo        - %%~nxf
echo.
echo [INFO] Reinicia Claude Code para que detecte los nuevos skills.
echo =============================================================
echo.
endlocal
exit /b 0

REM -----------------------------------------------------------
:DO_COPY
REM -----------------------------------------------------------
set "FILE=%~1"
copy /y "%SKILLS_SRC%\%FILE%" "%SKILLS_DEST%\%FILE%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No se pudo copiar: %FILE%
) else (
    echo [OK] Copiado: %FILE%
    set /a COUNT+=1
)
exit /b 0
