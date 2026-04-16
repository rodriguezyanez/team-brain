@echo off
REM =============================================================
REM brain.bat — Comandos rapidos para Team Brain en Windows
REM Uso:
REM   brain.bat up       -> levantar Neo4j
REM   brain.bat down     -> detener Neo4j
REM   brain.bat restart  -> reiniciar Neo4j
REM   brain.bat status   -> ver estado del contenedor
REM   brain.bat logs     -> ver logs en vivo
REM   brain.bat browser  -> abrir Neo4j Browser en Chrome
REM   brain.bat mcp      -> registrar MCP team-brain y Context7 en Claude Code
REM   brain.bat update   -> sincronizacion incremental de Neo4j (preserva memoria)
REM   brain.bat sync     -> sincronizar memorias pendientes locales con Neo4j
REM   brain.bat export [archivo.json] -> exportar grafo completo a JSON
REM   brain.bat import <archivo.json> -> mergear export de otro dev en este Neo4j
REM =============================================================

setlocal

set ACTION=%~1
if "%ACTION%"=="" goto SHOW_HELP

if /i "%ACTION%"=="up"      goto DO_UP
if /i "%ACTION%"=="down"    goto DO_DOWN
if /i "%ACTION%"=="restart" goto DO_RESTART
if /i "%ACTION%"=="status"  goto DO_STATUS
if /i "%ACTION%"=="logs"    goto DO_LOGS
if /i "%ACTION%"=="browser" goto DO_BROWSER
if /i "%ACTION%"=="mcp"     goto DO_MCP
if /i "%ACTION%"=="update"  goto DO_UPDATE
if /i "%ACTION%"=="sync"    goto DO_SYNC
if /i "%ACTION%"=="export"  goto DO_EXPORT
if /i "%ACTION%"=="import"  goto DO_IMPORT
goto SHOW_HELP

:DO_UP
echo.
echo Levantando Team Brain...
docker compose up -d
if %ERRORLEVEL% equ 0 (
    echo [OK] Neo4j corriendo.
    echo      Browser: http://localhost:7474
    echo      Bolt:    bolt://localhost:7687
) else (
    echo [ERROR] Fallo al levantar. Verifica que Docker Desktop este abierto.
)
goto END

:DO_DOWN
echo.
echo Deteniendo Team Brain...
docker compose down
echo [OK] Contenedor detenido. Los datos persisten en los volumenes.
goto END

:DO_RESTART
echo.
echo Reiniciando Neo4j...
docker compose restart neo4j
echo [OK] Reiniciado.
goto END

:DO_STATUS
echo.
docker compose ps
goto END

:DO_LOGS
echo.
echo Mostrando logs en vivo (Ctrl+C para salir)...
echo.
docker compose logs -f neo4j
goto END

:DO_BROWSER
echo.
echo Abriendo Neo4j Browser...
start "" "http://localhost:7474"
goto END

:DO_MCP
echo.
echo Registrando MCPs en Claude Code...
echo.
echo IMPORTANTE: Reemplaza team-brain-2025 por tu password si la cambiaste.
echo.

echo Registrando team-brain...
claude mcp add-json "team-brain" "{\"command\":\"npx\",\"args\":[\"-y\",\"@knowall-ai/mcp-neo4j-agent-memory\"],\"env\":{\"NEO4J_URI\":\"bolt://localhost:7687\",\"NEO4J_USERNAME\":\"neo4j\",\"NEO4J_PASSWORD\":\"team-brain-2025\",\"NEO4J_DATABASE\":\"neo4j\"}}" --scope user

echo.
echo Registrando Context7 (documentacion en tiempo real)...
claude mcp add-json "context7" "{\"command\":\"npx\",\"args\":[\"-y\",\"@upstash/context7-mcp\"]}" --scope user

if %ERRORLEVEL% equ 0 (
    echo.
    echo [OK] MCPs registrados. Verificando...
    claude mcp list
) else (
    echo.
    echo [ERROR] Fallo el registro de algun MCP.
    echo         Asegurate de tener Claude Code instalado:
    echo         npm install -g @anthropic-ai/claude-code
)
goto END

:DO_UPDATE
echo.
echo Sincronizando arquitectura de referencia en Neo4j...
echo (Preserva decisiones, bugs, patterns y memoria del equipo)
echo.
if exist "%~dp0brain-update.bat" (
    call "%~dp0brain-update.bat"
) else (
    echo [ERROR] brain-update.bat no encontrado en windows\.
)
goto END

:DO_SYNC
echo.
echo Sincronizando memorias pendientes locales con Neo4j...
echo.
if exist "%~dp0brain-sync.bat" (
    call "%~dp0brain-sync.bat"
) else (
    echo [ERROR] brain-sync.bat no encontrado en windows\.
)
goto END

:DO_EXPORT
echo.
echo Exportando grafo de Neo4j a JSON...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0brain-export.ps1" -OutputFile "%~2"
goto END

:DO_IMPORT
echo.
if "%~2"=="" (
    echo [ERROR] Debes indicar el archivo a importar.
    echo         Uso: brain.bat import ^<archivo.json^>
    goto END
)
echo Importando y mergeando grafo desde "%~2"...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0brain-import.ps1" -InputFile "%~2"
goto END

:SHOW_HELP
echo.
echo Team Brain -- Comandos disponibles:
echo.
echo   brain.bat up                  Levantar Neo4j
echo   brain.bat down                Detener Neo4j ^(datos persisten^)
echo   brain.bat restart             Reiniciar Neo4j
echo   brain.bat status              Ver estado del contenedor
echo   brain.bat logs                Ver logs en vivo
echo   brain.bat browser             Abrir Neo4j Browser
echo   brain.bat mcp                 Registrar MCPs ^(team-brain + Context7^) en Claude Code
echo   brain.bat update              Sincronizar arquitectura en Neo4j ^(preserva memoria^)
echo   brain.bat sync                Sincronizar memorias pendientes locales con Neo4j
echo   brain.bat export [file.json]  Exportar grafo completo a JSON
echo   brain.bat import ^<file.json^>  Mergear export de otro dev en este Neo4j
echo.

:END
endlocal