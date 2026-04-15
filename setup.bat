@echo off
REM =============================================================
REM setup.bat — Instalador unificado de Team Brain (Windows)
REM
REM Uso:
REM   setup.bat
REM
REM Orquesta todo el setup de primer uso en un solo comando:
REM   1. Verifica prerequisitos
REM   2. Levanta Neo4j
REM   3. Inicializa la base de datos
REM   4. Carga la arquitectura de referencia KLAP BYSF
REM   5. Registra el MCP en Claude Code
REM   6. Instala CLAUDE.md en el perfil del usuario
REM =============================================================

setlocal EnableDelayedExpansion

echo.
echo =====================================================
echo   Team Brain -- Instalador unificado
echo   KLAP BYSF Knowledge Graph Setup
echo =====================================================
echo.

REM =============================================================
REM PASO 0: Detectar password desde docker-compose.yml
REM =============================================================
set NEO4J_PASS=team-brain-2025

for /f "tokens=2 delims=/" %%a in ('findstr "NEO4J_AUTH" docker-compose.yml 2^>NUL') do (
    set NEO4J_PASS=%%a
)
REM Limpiar espacios y caracteres extra
for /f "tokens=* delims= " %%a in ("!NEO4J_PASS!") do set NEO4J_PASS=%%a

echo [Config] Password Neo4j detectada desde docker-compose.yml: !NEO4J_PASS!
echo.

REM =============================================================
REM PASO 1: Verificar prerequisitos
REM =============================================================
echo ── PASO 1: Verificando prerequisitos ─────────────────────
echo.

set ERRORS=0

REM -- Docker --
docker info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] Docker Desktop no esta corriendo.
    echo          Abre Docker Desktop y vuelve a ejecutar setup.bat
    set /a ERRORS+=1
) else (
    echo   [OK]    Docker Desktop corriendo
)

REM -- Docker Compose --
docker compose version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] docker compose no disponible.
    echo          Actualiza Docker Desktop a una version reciente.
    set /a ERRORS+=1
) else (
    echo   [OK]    docker compose disponible
)

REM -- Node.js >= 18 --
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] Node.js no encontrado.
    echo          Instala Node.js 18+ desde https://nodejs.org
    set /a ERRORS+=1
) else (
    for /f "tokens=1 delims=v" %%v in ('node --version 2^>NUL') do set NODE_RAW=%%v
    for /f "tokens=1 delims=." %%m in ('node --version 2^>NUL') do (
        set NODE_MAJOR=%%m
        set NODE_MAJOR=!NODE_MAJOR:v=!
    )
    if !NODE_MAJOR! geq 18 (
        echo   [OK]    Node.js !NODE_MAJOR! instalado
    ) else (
        echo   [WARN]  Node.js !NODE_MAJOR! detectado. Se recomienda Node.js 18+.
    )
)

REM -- curl --
where curl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] curl no encontrado. Es necesario para inicializar Neo4j.
    set /a ERRORS+=1
) else (
    echo   [OK]    curl disponible
)

REM -- Claude Code --
where claude >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [WARN]  Claude Code (claude CLI) no encontrado.
    echo          El MCP no se podra registrar automaticamente.
    echo          Instala con: npm install -g @anthropic-ai/claude-code
    set CLAUDE_AVAILABLE=0
) else (
    echo   [OK]    Claude Code instalado
    set CLAUDE_AVAILABLE=1
)

if %ERRORS% gtr 0 (
    echo.
    echo   Se encontraron %ERRORS% error(es) critico(s). Corrigelos y vuelve a ejecutar.
    echo.
    goto END_FAILURE
)

echo.
echo   Todos los prerequisitos OK.
echo.

REM =============================================================
REM PASO 2: Levantar Neo4j
REM =============================================================
echo ── PASO 2: Levantando Neo4j ───────────────────────────────
echo.

docker compose up -d
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] No se pudo levantar Neo4j.
    echo          Verifica docker-compose.yml y que Docker Desktop este abierto.
    goto END_FAILURE
)
echo   [OK] Contenedor Neo4j iniciado.
echo.

REM =============================================================
REM PASO 3: Esperar que Neo4j este listo y ejecutar init-brain
REM =============================================================
echo ── PASO 3: Inicializando base de datos ────────────────────
echo.

call windows\init-brain.bat
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] windows\init-brain.bat fallo.
    goto END_FAILURE
)
echo.

REM =============================================================
REM PASO 4: Cargar arquitectura de referencia KLAP BYSF
REM =============================================================
echo ── PASO 4: Cargando arquitectura KLAP BYSF ────────────────
echo.

if exist windows\enrich-brain.bat (
    call windows\enrich-brain.bat
    if %ERRORLEVEL% neq 0 (
        echo   [WARN] enrich-brain.bat termino con errores. Continuando...
    ) else (
        echo   [OK] Arquitectura de referencia cargada en Neo4j.
    )
) else (
    echo   [WARN] windows\enrich-brain.bat no encontrado. Saltando enriquecimiento.
)
echo.

REM =============================================================
REM PASO 5: Registrar MCP en Claude Code
REM =============================================================
echo ── PASO 5: Registrando MCP en Claude Code ─────────────────
echo.

if "%CLAUDE_AVAILABLE%"=="1" (
    set MCP_CONFIG={"command":"npx","args":["-y","@knowall-ai/mcp-neo4j-agent-memory"],"env":{"NEO4J_URI":"bolt://localhost:7687","NEO4J_USERNAME":"neo4j","NEO4J_PASSWORD":"!NEO4J_PASS!","NEO4J_DATABASE":"neo4j"}}

    claude mcp add-json "team-brain" "!MCP_CONFIG!" --scope user >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   [OK] MCP team-brain registrado con scope user.
    ) else (
        echo   [INFO] MCP ya registrado o fallo el registro.
        echo         Verifica con: claude mcp list
    )
) else (
    echo   [SKIP] Claude Code no disponible. Registra el MCP manualmente con:
    echo          brain.bat mcp
)
echo.

REM =============================================================
REM PASO 5b: Registrar Context7 MCP (opcional — docs en tiempo real)
REM =============================================================
echo ── PASO 5b: Registrando Context7 MCP (opcional) ──────────
echo.

if "%CLAUDE_AVAILABLE%"=="1" (
    claude mcp add-json "context7" "{\"command\":\"npx\",\"args\":[\"-y\",\"@upstash/context7-mcp\"]}" --scope user >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   [OK] Context7 registrado. Agrega "use context7" a tus prompts para docs en tiempo real.
    ) else (
        echo   [INFO] Context7 ya registrado o no disponible. Continua...
    )
) else (
    echo   [SKIP] Claude Code no disponible. Registra Context7 con: windows\install-context7.bat
)
echo.

REM =============================================================
REM PASO 5c: Registrar Sequential Thinking MCP
REM =============================================================
echo ── PASO 5c: Registrando Sequential Thinking MCP ──────────
echo.

if "%CLAUDE_AVAILABLE%"=="1" (
    claude mcp add-json "sequential-thinking" "{\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-sequential-thinking\"]}" --scope user >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   [OK] Sequential Thinking MCP registrado.
    ) else (
        echo   [INFO] Sequential Thinking ya registrado o no disponible. Continua...
    )
) else (
    echo   [SKIP] Claude Code no disponible. Registra Sequential Thinking manualmente.
)
echo.

REM =============================================================
REM PASO 5d: Instalar plugins de Claude Code
REM (superpowers, context-mode, context7-plugin)
REM Se configuran via settings.json — no via mcp add-json
REM =============================================================
echo ── PASO 5d: Instalando plugins Claude Code ────────────────
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$s='%USERPROFILE%\.claude\settings.json'; $cfg=@{}; if(Test-Path $s){try{$cfg=Get-Content $s -Raw|ConvertFrom-Json -AsHashtable}catch{}}; if(-not $cfg.ContainsKey('enabledPlugins')){$cfg['enabledPlugins']=@{}}; $cfg['enabledPlugins']['superpowers@claude-plugins-official']=$true; $cfg['enabledPlugins']['context-mode@context-mode']=$true; $cfg['enabledPlugins']['context7@claude-plugins-official']=$true; $cfg['enabledPlugins']['code-simplifier@claude-plugins-official']=$true; $cfg['enabledPlugins']['code-review@claude-plugins-official']=$true; $cfg['enabledPlugins']['pr-review-toolkit@claude-plugins-official']=$true; $cfg['enabledPlugins']['commit-commands@claude-plugins-official']=$true; $cfg['enabledPlugins']['feature-dev@claude-plugins-official']=$true; $cfg['enabledPlugins']['claude-md-management@claude-plugins-official']=$true; if(-not $cfg.ContainsKey('extraKnownMarketplaces')){$cfg['extraKnownMarketplaces']=@{}}; $cfg['extraKnownMarketplaces']['context-mode']=@{source=@{source='github';repo='mksglu/context-mode'}}; $cfg|ConvertTo-Json -Depth 10|Set-Content $s -Encoding UTF8; Write-Host '  [OK] Plugins registrados: superpowers, context-mode, context7, code-simplifier, code-review, pr-review-toolkit, commit-commands, feature-dev, claude-md-management'"

echo   [INFO] Atlassian Rovo requiere autenticacion OAuth manual.
echo          Conecta tu cuenta en: https://claude.ai/settings/integrations
echo.

REM =============================================================
REM PASO 6: Instalar skill files locales en Claude Code
REM =============================================================
echo ── PASO 6: Instalando skills locales ──────────────────────
echo.

if exist windows\install-skills.bat (
    call windows\install-skills.bat
    if %ERRORLEVEL% neq 0 (
        echo   [WARN] install-skills.bat termino con errores. Continuando...
    )
) else (
    echo   [SKIP] windows\install-skills.bat no encontrado. Saltando skills locales.
)
echo.

REM =============================================================
REM PASO 7: Instalar CLAUDE.md en el perfil del usuario
REM =============================================================
echo ── PASO 7: Instalando CLAUDE.md ───────────────────────────
echo.

if exist CLAUDE.md (
    if not exist "%USERPROFILE%\.claude" (
        mkdir "%USERPROFILE%\.claude"
    )

    if exist "%USERPROFILE%\.claude\CLAUDE.md" (
        echo   [INFO] Ya existe %USERPROFILE%\.claude\CLAUDE.md
        echo         Creando backup: CLAUDE.md.bak
        copy /y "%USERPROFILE%\.claude\CLAUDE.md" "%USERPROFILE%\.claude\CLAUDE.md.bak" >nul
    )

    copy /y CLAUDE.md "%USERPROFILE%\.claude\CLAUDE.md" >nul
    if %ERRORLEVEL% equ 0 (
        echo   [OK] CLAUDE.md instalado en %USERPROFILE%\.claude\CLAUDE.md
    ) else (
        echo   [WARN] No se pudo copiar CLAUDE.md. Copíalo manualmente.
    )
) else (
    echo   [SKIP] CLAUDE.md no encontrado en el directorio actual.
)
echo.

REM =============================================================
REM PASO 8: Guardian Angel hook pre-commit (opcional)
REM =============================================================
echo ── PASO 8: Guardian Angel hook pre-commit (opcional) ──────
echo.
echo   Para instalar el hook en tu proyecto:
echo     windows\install-hooks.bat C:\ruta\a\tu\proyecto
echo.
echo   El hook revisara cada commit Java/Kotlin contra las reglas del equipo.
echo   Bypass urgente: git commit --no-verify
echo.

REM =============================================================
REM RESUMEN FINAL
REM =============================================================
echo =====================================================
echo   Team Brain instalado correctamente!
echo =====================================================
echo.
echo   Neo4j Browser : http://localhost:7474
echo   Usuario       : neo4j
echo   Password      : !NEO4J_PASS!
echo   Bolt URI      : bolt://localhost:7687
echo.
echo   MCPs registrados:
echo     team-brain, context7, sequential-thinking
echo   Plugins registrados:
echo     superpowers, context-mode, context7
echo     code-simplifier, code-review, pr-review-toolkit
echo     commit-commands, feature-dev, claude-md-management
echo   Atlassian Rovo (OAuth manual): https://claude.ai/settings/integrations
echo.
echo   Verificar conexion MCP:
echo     claude mcp list
echo.
echo   Verificar grafo en Neo4j Browser:
echo     MATCH (n:Entity) RETURN n
echo.
echo   Proximos pasos:
echo     1. Abre Claude Code en tu proyecto
echo     2. Indica el microservicio en el que vas a trabajar
echo.
echo   Operacion diaria:
echo     windows\brain.bat up      <- levantar Neo4j
echo     windows\brain.bat down    <- detener Neo4j
echo     windows\brain.bat status  <- ver estado
echo =====================================================
echo.
goto END_SUCCESS

:END_FAILURE
echo.
echo   [FALLO] Setup incompleto. Revisa los errores arriba.
echo.
endlocal
exit /b 1

:END_SUCCESS
endlocal
exit /b 0
