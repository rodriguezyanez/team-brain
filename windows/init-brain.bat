@echo off
REM =============================================================
REM init-brain.bat — Inicializa Team Brain en Neo4j Community
REM Usa archivos JSON temporales para evitar problemas de escaping
REM =============================================================

setlocal EnableDelayedExpansion

set NEO4J_HOST=localhost
set NEO4J_PORT=7474
set NEO4J_USER=neo4j
set NEO4J_PASS=team-brain-2025
set BASE_URL=http://%NEO4J_HOST%:%NEO4J_PORT%
set USE_DB=neo4j
set TMP_JSON=%TEMP%\neo4j_query.json

echo.
echo =====================================================
echo   Team Brain -- Inicializacion de base de datos
echo =====================================================
echo   Host: %BASE_URL%
echo   DB  : %USE_DB%
echo.

where curl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] curl no encontrado.
    exit /b 1
)

REM ── Esperar Neo4j ────────────────────────────────────────────
echo Esperando que Neo4j este disponible...
set /a ATTEMPTS=0

:WAIT_LOOP
set /a ATTEMPTS+=1
if %ATTEMPTS% gtr 30 (
    echo [ERROR] Neo4j no respondio. Verifica con: brain.bat status
    exit /b 1
)
echo {"statements":[{"statement":"RETURN 1"}]} > "%TMP_JSON%"
for /f "delims=" %%i in ('curl -s -o NUL -w "%%{http_code}" -u "%NEO4J_USER%:%NEO4J_PASS%" "%BASE_URL%/db/%USE_DB%/tx/commit" -H "Content-Type: application/json" -d @"%TMP_JSON%" 2^>NUL') do set STATUS=%%i
if "%STATUS%"=="200" goto NEO4J_READY
if "%STATUS%"=="201" goto NEO4J_READY
echo   Intento %ATTEMPTS%/30... (HTTP %STATUS%)
timeout /t 3 /nobreak >nul
goto WAIT_LOOP

:NEO4J_READY
echo [OK] Neo4j listo.
echo.

REM ── Constraints e indices ────────────────────────────────────
echo Creando constraints e indices...

echo {"statements":[{"statement":"CREATE CONSTRAINT entity_name IF NOT EXISTS FOR (n:Entity) REQUIRE n.name IS UNIQUE"}]} > "%TMP_JSON%"
call :RUN_JSON "Constraint Entity.name unico"

echo {"statements":[{"statement":"CREATE INDEX entity_type_idx IF NOT EXISTS FOR (n:Entity) ON (n.entityType)"}]} > "%TMP_JSON%"
call :RUN_JSON "Indice Entity.entityType"

echo {"statements":[{"statement":"CREATE INDEX observation_idx IF NOT EXISTS FOR (n:Observation) ON (n.content)"}]} > "%TMP_JSON%"
call :RUN_JSON "Indice Observation.content"

echo {"statements":[{"statement":"CREATE INDEX entity_created_idx IF NOT EXISTS FOR (n:Entity) ON (n.createdAt)"}]} > "%TMP_JSON%"
call :RUN_JSON "Indice Entity.createdAt"

REM ── Nodos base ───────────────────────────────────────────────
echo.
echo Creando nodos base del equipo...

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Team', entityType: 'Organization'}) SET t.createdAt = datetime(), t.description = 'Equipo de desarrollo'"}]} > "%TMP_JSON%"
call :RUN_JSON "Nodo Team"

echo {"statements":[{"statement":"MERGE (p:Entity {name: 'Architecture', entityType: 'Topic'}) SET p.createdAt = datetime()"}]} > "%TMP_JSON%"
call :RUN_JSON "Nodo Architecture"

echo {"statements":[{"statement":"MERGE (d:Entity {name: 'Decisions', entityType: 'Topic'}) SET d.createdAt = datetime()"}]} > "%TMP_JSON%"
call :RUN_JSON "Nodo Decisions"

echo {"statements":[{"statement":"MERGE (c:Entity {name: 'Conventions', entityType: 'Topic'}) SET c.createdAt = datetime()"}]} > "%TMP_JSON%"
call :RUN_JSON "Nodo Conventions"

REM ── Verificar resultado ───────────────────────────────────────
echo.
echo {"statements":[{"statement":"MATCH (e:Entity) RETURN count(e) as total"}]} > "%TMP_JSON%"
for /f "delims=" %%i in ('curl -s -u "%NEO4J_USER%:%NEO4J_PASS%" "%BASE_URL%/db/%USE_DB%/tx/commit" -H "Content-Type: application/json" -d @"%TMP_JSON%" 2^>NUL') do set VERIFY=%%i
echo Verificacion: %VERIFY%

del "%TMP_JSON%" >nul 2>&1

echo.
echo =====================================================
echo   [OK] Team Brain inicializado correctamente
echo.
echo   Neo4j Browser : %BASE_URL%
echo   Usuario       : %NEO4J_USER%
echo   Base de datos : %USE_DB%
echo   Bolt URI      : bolt://%NEO4J_HOST%:7687
echo =====================================================
echo.
echo Proximo paso:
echo   brain.bat mcp
echo.

endlocal
exit /b 0

REM =============================================================
:RUN_JSON <descripcion>
REM Lee el JSON desde %TMP_JSON% y lo envia a Neo4j
REM =============================================================
set _DESC=%~1
<nul set /p "=  -> %_DESC%... "
for /f "delims=" %%i in ('curl -s -o NUL -w "%%{http_code}" -u "%NEO4J_USER%:%NEO4J_PASS%" "%BASE_URL%/db/%USE_DB%/tx/commit" -H "Content-Type: application/json" -d @"%TMP_JSON%" 2^>NUL') do set _ST=%%i
if "%_ST%"=="200" (echo [OK]) else (
if "%_ST%"=="201" (echo [OK]) else (
    echo [WARN] HTTP %_ST%
))
exit /b 0