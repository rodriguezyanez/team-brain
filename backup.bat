@echo off
REM =============================================================
REM backup.bat — Backup y restore de los volumenes de Neo4j
REM Uso:
REM   backup.bat             -> crear backup
REM   backup.bat restore <archivo> -> restaurar backup
REM   backup.bat list        -> listar backups disponibles
REM =============================================================

setlocal EnableDelayedExpansion

set BACKUP_DIR=backups

REM Timestamp: YYYYMMDD_HHMMSS
for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value 2^>nul') do set DATETIME=%%i
set TIMESTAMP=%DATETIME:~0,8%_%DATETIME:~8,6%

set ACTION=%~1
if "%ACTION%"=="" set ACTION=backup

if /i "%ACTION%"=="backup"  goto DO_BACKUP
if /i "%ACTION%"=="restore" goto DO_RESTORE
if /i "%ACTION%"=="list"    goto DO_LIST

echo Uso: backup.bat [backup ^| restore ^<archivo^> ^| list]
exit /b 1

REM =============================================================
:DO_BACKUP
REM =============================================================
echo.
echo Creando backup...

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

set BACKUP_FILE=%BACKUP_DIR%\neo4j-backup-%TIMESTAMP%.tar.gz

echo   Archivo: %BACKUP_FILE%

docker run --rm ^
    -v team-brain_neo4j_data:/data ^
    -v "%CD%\%BACKUP_DIR%":/backup ^
    alpine ^
    tar czf /backup/neo4j-backup-%TIMESTAMP%.tar.gz /data

if %ERRORLEVEL% equ 0 (
    echo [OK] Backup creado: %BACKUP_FILE%
) else (
    echo [ERROR] Fallo al crear el backup. Verifica que Docker este corriendo.
    exit /b 1
)
goto END

REM =============================================================
:DO_RESTORE
REM =============================================================
set RESTORE_FILE=%~2

REM Convertir backslashes a forward slashes para el contenedor Alpine
set RESTORE_FILE_FWD=%RESTORE_FILE:\=/%

if "%RESTORE_FILE%"=="" (
    echo [ERROR] Especifica el archivo a restaurar.
    echo         Ejemplo: backup.bat restore backups\neo4j-backup-20250410_120000.tar.gz
    exit /b 1
)

if not exist "%RESTORE_FILE%" (
    echo [ERROR] Archivo no encontrado: %RESTORE_FILE%
    exit /b 1
)

echo.
echo ADVERTENCIA: esto sobreescribira los datos actuales de Neo4j.
set /p CONFIRM=¿Continuar? (s/N): 

if /i not "%CONFIRM%"=="s" (
    echo Cancelado.
    goto END
)

echo.
echo Deteniendo Neo4j...
docker compose down

echo Restaurando desde %RESTORE_FILE%...
docker run --rm ^
    -v team-brain_neo4j_data:/data ^
    -v "%CD%":/backup ^
    alpine ^
    sh -c "rm -rf /data/* && tar xzf /backup/%RESTORE_FILE_FWD% -C / --strip-components=0"

if %ERRORLEVEL% equ 0 (
    echo Reiniciando Neo4j...
    docker compose up -d
    echo [OK] Restauracion completa.
) else (
    echo [ERROR] Fallo la restauracion.
    echo         Levanta Neo4j manualmente con: docker compose up -d
    exit /b 1
)
goto END

REM =============================================================
:DO_LIST
REM =============================================================
echo.
echo Backups disponibles en %BACKUP_DIR%\:
echo.

if not exist "%BACKUP_DIR%" (
    echo   (ninguno)
    goto END
)

set FOUND=0
for %%f in ("%BACKUP_DIR%\neo4j-backup-*.tar.gz") do (
    set FOUND=1
    echo   %%~nxf  ^(%%~zf bytes^)
)

if "%FOUND%"=="0" echo   (ninguno)
goto END

REM =============================================================
:END
endlocal
