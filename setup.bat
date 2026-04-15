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

if /i "%~1"=="--uninstall" goto UNINSTALL

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
REM PASO 0b: Backup de configuracion del usuario
REM (se ejecuta una sola vez; si ya existe backup, se omite)
REM =============================================================
echo -- PASO 0b: Backup de configuracion del usuario ------------
echo.

set "BACKUP_DIR=%USERPROFILE%\.claude\team-brain-backup"

if exist "!BACKUP_DIR!\" (
    echo   [INFO] Backup previo detectado en !BACKUP_DIR!
    echo          Se omite para preservar el estado original del usuario.
) else (
    mkdir "!BACKUP_DIR!" >nul 2>&1

    if exist "%USERPROFILE%\.claude.json" (
        copy /y "%USERPROFILE%\.claude.json" "!BACKUP_DIR!\claude.json" >nul
        echo   [OK] Backup: .claude.json
    ) else (
        echo   [INFO] .claude.json no existe aun. Se omite.
    )

    if exist "%USERPROFILE%\.claude\settings.json" (
        copy /y "%USERPROFILE%\.claude\settings.json" "!BACKUP_DIR!\settings.json" >nul
        echo   [OK] Backup: settings.json
    ) else (
        echo   [INFO] settings.json no existe aun. Se omite.
    )

    if exist "%USERPROFILE%\.claude\CLAUDE.md" (
        copy /y "%USERPROFILE%\.claude\CLAUDE.md" "!BACKUP_DIR!\CLAUDE.md" >nul
        echo   [OK] Backup: CLAUDE.md
    ) else (
        echo   [INFO] CLAUDE.md no existe aun. Se omite.
    )

    set "SKILLS_SRC=%USERPROFILE%\.claude\skills"
    if exist "!SKILLS_SRC!\" (
        mkdir "!BACKUP_DIR!\skills" >nul 2>&1
        for %%f in ("!SKILLS_SRC!\*.md") do (
            copy /y "%%f" "!BACKUP_DIR!\skills\%%~nxf" >nul 2>&1
            echo   [OK] Backup skill: %%~nxf
        )
    ) else (
        echo   [INFO] Directorio skills no existe aun. Se omite.
    )

    echo   [OK] Backup guardado en: !BACKUP_DIR!
)
echo.

REM =============================================================
REM PASO 1: Verificar prerequisitos
REM =============================================================
echo -- PASO 1: Verificando prerequisitos -----------------------
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
set CLAUDE_AVAILABLE=0
powershell -NoProfile -Command "if (Get-Command claude -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo   [OK]    Claude Code instalado
    set CLAUDE_AVAILABLE=1
) else (
    echo   [WARN]  Claude Code ^(claude CLI^) no encontrado.
    echo          El MCP no se podra registrar automaticamente.
    echo          Instala con: npm install -g @anthropic-ai/claude-code
)

if %ERRORS% gtr 0 (
    echo.
    echo   Se encontraron %ERRORS% errores criticos. Corrigelos y vuelve a ejecutar.
    echo.
    goto END_FAILURE
)

echo.
echo   Todos los prerequisitos OK.
echo.

REM =============================================================
REM PASO 2: Levantar Neo4j
REM =============================================================
echo -- PASO 2: Levantando Neo4j --------------------------------
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
echo -- PASO 3: Inicializando base de datos ---------------------
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
echo -- PASO 4: Cargando arquitectura KLAP BYSF -----------------
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
REM PASO 5: Registrar MCPs (team-brain, context7, sequential-thinking)
REM Escribe directo al .claude.json para evitar quoting issues del CLI
REM =============================================================
echo -- PASO 5: Registrando MCPs en Claude Code -----------------
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$cf='%USERPROFILE%\.claude.json';$pass='!NEO4J_PASS!';$cfg=@{};if(Test-Path $cf){try{$cfg=Get-Content $cf -Raw|ConvertFrom-Json -AsHashtable}catch{}};if(-not $cfg.ContainsKey('mcpServers')){$cfg['mcpServers']=@{}};$ch=$false;if(-not $cfg['mcpServers'].ContainsKey('team-brain')){$cfg['mcpServers']['team-brain']=@{command='npx';args=@('-y','@knowall-ai/mcp-neo4j-agent-memory');env=@{NEO4J_URI='bolt://localhost:7687';NEO4J_USERNAME='neo4j';NEO4J_PASSWORD=$pass;NEO4J_DATABASE='neo4j'}};$ch=$true;Write-Host '  [OK] team-brain registrado.'}else{Write-Host '  [INFO] team-brain ya registrado. Saltando.'};if(-not $cfg['mcpServers'].ContainsKey('context7')){$cfg['mcpServers']['context7']=@{command='npx';args=@('-y','@upstash/context7-mcp')};$ch=$true;Write-Host '  [OK] context7 registrado.'}else{Write-Host '  [INFO] context7 ya registrado. Saltando.'};if(-not $cfg['mcpServers'].ContainsKey('sequential-thinking')){$cfg['mcpServers']['sequential-thinking']=@{command='npx';args=@('-y','@modelcontextprotocol/server-sequential-thinking')};$ch=$true;Write-Host '  [OK] sequential-thinking registrado.'}else{Write-Host '  [INFO] sequential-thinking ya registrado. Saltando.'};if($ch){$cfg|ConvertTo-Json -Depth 10|Set-Content $cf -Encoding UTF8}"

echo.

REM =============================================================
REM PASO 5d: Instalar plugins de Claude Code
REM (superpowers, context-mode, context7-plugin)
REM Se configuran via settings.json — no via mcp add-json
REM =============================================================
echo -- PASO 5d: Instalando plugins Claude Code -----------------
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$s='%USERPROFILE%\.claude\settings.json'; $cfg=@{}; if(Test-Path $s){try{$cfg=Get-Content $s -Raw|ConvertFrom-Json -AsHashtable}catch{}}; if(-not $cfg.ContainsKey('enabledPlugins')){$cfg['enabledPlugins']=@{}}; $cfg['enabledPlugins']['superpowers@claude-plugins-official']=$true; $cfg['enabledPlugins']['context-mode@context-mode']=$true; $cfg['enabledPlugins']['context7@claude-plugins-official']=$true; $cfg['enabledPlugins']['code-simplifier@claude-plugins-official']=$true; $cfg['enabledPlugins']['code-review@claude-plugins-official']=$true; $cfg['enabledPlugins']['pr-review-toolkit@claude-plugins-official']=$true; $cfg['enabledPlugins']['commit-commands@claude-plugins-official']=$true; $cfg['enabledPlugins']['feature-dev@claude-plugins-official']=$true; $cfg['enabledPlugins']['claude-md-management@claude-plugins-official']=$true; if(-not $cfg.ContainsKey('extraKnownMarketplaces')){$cfg['extraKnownMarketplaces']=@{}}; $cfg['extraKnownMarketplaces']['context-mode']=@{source=@{source='github';repo='mksglu/context-mode'}}; $cfg|ConvertTo-Json -Depth 10|Set-Content $s -Encoding UTF8; Write-Host '  [OK] Plugins registrados: superpowers, context-mode, context7, code-simplifier, code-review, pr-review-toolkit, commit-commands, feature-dev, claude-md-management'"

echo   [INFO] Atlassian Rovo requiere autenticacion OAuth manual.
echo          Conecta tu cuenta en: https://claude.ai/settings/integrations
echo.

REM =============================================================
REM PASO 6: Instalar skill files locales en Claude Code
REM =============================================================
echo -- PASO 6: Instalando skills locales -----------------------
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
echo -- PASO 7: Instalando CLAUDE.md ----------------------------
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
    if !ERRORLEVEL! equ 0 (
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
echo -- PASO 8: Guardian Angel hook pre-commit (opcional) -------
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
echo     windows\brain.bat up      ^<- levantar Neo4j
echo     windows\brain.bat down    ^<- detener Neo4j
echo     windows\brain.bat status  ^<- ver estado
echo =====================================================
echo.
goto END_SUCCESS

:UNINSTALL
echo.
echo =====================================================
echo   Team Brain -- Desinstalador
echo   KLAP BYSF Knowledge Graph Uninstall
echo =====================================================
echo.
echo   Este proceso eliminara:
echo     - Contenedor Neo4j y sus datos (docker compose down -v)
echo     - MCPs: team-brain, context7, sequential-thinking
echo     - Plugins de Claude Code
echo     - Skills locales de %USERPROFILE%\.claude\skills\
echo     - CLAUDE.md de %USERPROFILE%\.claude\
echo.
echo   Los programas instalados (Docker, Node.js, Claude Code)
echo   NO seran desinstalados.
echo.
set /p CONFIRM="   Confirmar desinstalacion? [s/N]: "
if /i not "!CONFIRM!"=="s" (
    echo.
    echo   Desinstalacion cancelada.
    echo.
    endlocal
    exit /b 0
)
echo.

REM -- 1. Detener y eliminar Neo4j + datos -----------------------
echo -- Deteniendo Neo4j y eliminando datos ---------------------
docker compose down -v >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   [OK] Contenedor Neo4j detenido y datos eliminados.
) else (
    echo   [WARN] No se pudo detener Neo4j o ya estaba detenido.
)
echo.

set "BACKUP_DIR=%USERPROFILE%\.claude\team-brain-backup"

if exist "!BACKUP_DIR!\" (
    REM ── Restauracion completa desde backup ──────────────────────

    REM -- 2. Restaurar .claude.json --------------------------------
    echo -- Restaurando .claude.json --------------------------------
    if exist "!BACKUP_DIR!\claude.json" (
        copy /y "!BACKUP_DIR!\claude.json" "%USERPROFILE%\.claude.json" >nul
        echo   [OK] .claude.json restaurado desde backup.
    ) else (
        if exist "%USERPROFILE%\.claude.json" (
            del /q "%USERPROFILE%\.claude.json" >nul
            echo   [OK] .claude.json eliminado (no existia antes de instalar).
        ) else (
            echo   [INFO] .claude.json no encontrado. Nada que restaurar.
        )
    )
    echo.

    REM -- 3. Restaurar settings.json --------------------------------
    echo -- Restaurando settings.json --------------------------------
    if exist "!BACKUP_DIR!\settings.json" (
        copy /y "!BACKUP_DIR!\settings.json" "%USERPROFILE%\.claude\settings.json" >nul
        echo   [OK] settings.json restaurado desde backup.
    ) else (
        if exist "%USERPROFILE%\.claude\settings.json" (
            del /q "%USERPROFILE%\.claude\settings.json" >nul
            echo   [OK] settings.json eliminado (no existia antes de instalar).
        ) else (
            echo   [INFO] settings.json no encontrado. Nada que restaurar.
        )
    )
    echo.

    REM -- 4. Restaurar skills --------------------------------------
    echo -- Restaurando skills --------------------------------------
    set "SKILLS_DIR=%USERPROFILE%\.claude\skills"
    for %%f in (kafka-config.md kafka-listener.md processor.md repository.md webclient.md exceptions.md testing.md openapi.md skill-registry.md sdd-microservice.md sdd-checklist.md) do (
        del /q "!SKILLS_DIR!\%%f" >nul 2>&1
    )
    if exist "!BACKUP_DIR!\skills\" (
        if not exist "!SKILLS_DIR!\" mkdir "!SKILLS_DIR!"
        for %%f in ("!BACKUP_DIR!\skills\*.md") do (
            copy /y "%%f" "!SKILLS_DIR!\%%~nxf" >nul 2>&1
            echo   [OK] Restaurado skill: %%~nxf
        )
    ) else (
        echo   [INFO] No habia skills previos. Skills de Team Brain eliminados.
    )
    echo.

    REM -- 5. Restaurar CLAUDE.md ------------------------------------
    echo -- Restaurando CLAUDE.md ------------------------------------
    if exist "!BACKUP_DIR!\CLAUDE.md" (
        copy /y "!BACKUP_DIR!\CLAUDE.md" "%USERPROFILE%\.claude\CLAUDE.md" >nul
        echo   [OK] CLAUDE.md restaurado desde backup.
    ) else (
        if exist "%USERPROFILE%\.claude\CLAUDE.md" (
            del /q "%USERPROFILE%\.claude\CLAUDE.md" >nul
            echo   [OK] CLAUDE.md eliminado (no existia antes de instalar).
        ) else (
            echo   [INFO] CLAUDE.md no encontrado. Nada que restaurar.
        )
    )
    echo.

    REM -- Eliminar directorio de backup ----------------------------
    rmdir /s /q "!BACKUP_DIR!" >nul 2>&1
    echo   [OK] Backup eliminado.
    echo.

) else (
    REM ── Sin backup: eliminar solo entradas de Team Brain ────────
    echo   [INFO] No se encontro backup previo.
    echo          Se eliminan solo las entradas de Team Brain.
    echo.

    REM -- 2. Eliminar MCPs de .claude.json -------------------------
    echo -- Eliminando MCPs de Claude Code --------------------------
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$cf='%USERPROFILE%\.claude.json'; if(Test-Path $cf){ try{ $cfg=Get-Content $cf -Raw|ConvertFrom-Json -AsHashtable }catch{ $cfg=@{} }; if($cfg.ContainsKey('mcpServers')){ @('team-brain','context7','sequential-thinking') | ForEach-Object { if($cfg['mcpServers'].ContainsKey($_)){ $cfg['mcpServers'].Remove($_); Write-Host \"  [OK] MCP '$_' eliminado.\" } else { Write-Host \"  [INFO] MCP '$_' no estaba registrado.\" } }; $cfg|ConvertTo-Json -Depth 10|Set-Content $cf -Encoding UTF8 } else { Write-Host '  [INFO] No habia MCPs registrados.' } } else { Write-Host '  [INFO] .claude.json no encontrado.' }"
    echo.

    REM -- 3. Eliminar plugins de settings.json ----------------------
    echo -- Eliminando plugins de Claude Code -----------------------
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$s='%USERPROFILE%\.claude\settings.json'; if(Test-Path $s){ try{ $cfg=Get-Content $s -Raw|ConvertFrom-Json -AsHashtable }catch{ $cfg=@{} }; $plugins=@('superpowers@claude-plugins-official','context-mode@context-mode','context7@claude-plugins-official','code-simplifier@claude-plugins-official','code-review@claude-plugins-official','pr-review-toolkit@claude-plugins-official','commit-commands@claude-plugins-official','feature-dev@claude-plugins-official','claude-md-management@claude-plugins-official'); if($cfg.ContainsKey('enabledPlugins')){ $plugins | ForEach-Object { if($cfg['enabledPlugins'].ContainsKey($_)){ $cfg['enabledPlugins'].Remove($_); Write-Host \"  [OK] Plugin '$_' eliminado.\" } } }; if($cfg.ContainsKey('extraKnownMarketplaces') -and $cfg['extraKnownMarketplaces'].ContainsKey('context-mode')){ $cfg['extraKnownMarketplaces'].Remove('context-mode'); Write-Host '  [OK] Marketplace context-mode eliminado.' }; $cfg|ConvertTo-Json -Depth 10|Set-Content $s -Encoding UTF8; Write-Host '  [OK] settings.json actualizado.' } else { Write-Host '  [INFO] settings.json no encontrado.' }"
    echo.

    REM -- 4. Eliminar skills de Team Brain --------------------------
    echo -- Eliminando skills locales --------------------------------
    set "SKILLS_DIR=%USERPROFILE%\.claude\skills"
    for %%f in (kafka-config.md kafka-listener.md processor.md repository.md webclient.md exceptions.md testing.md openapi.md skill-registry.md sdd-microservice.md sdd-checklist.md) do (
        if exist "!SKILLS_DIR!\%%f" (
            del /q "!SKILLS_DIR!\%%f" >nul 2>&1
            echo   [OK] Eliminado: %%f
        )
    )
    echo.

    REM -- 5. Restaurar o eliminar CLAUDE.md -------------------------
    echo -- Restaurando CLAUDE.md ------------------------------------
    set "CLAUDE_MD=%USERPROFILE%\.claude\CLAUDE.md"
    set "CLAUDE_BAK=%USERPROFILE%\.claude\CLAUDE.md.bak"
    if exist "!CLAUDE_BAK!" (
        copy /y "!CLAUDE_BAK!" "!CLAUDE_MD!" >nul
        del /q "!CLAUDE_BAK!" >nul
        echo   [OK] CLAUDE.md restaurado desde backup (.bak).
    ) else if exist "!CLAUDE_MD!" (
        del /q "!CLAUDE_MD!" >nul
        echo   [OK] CLAUDE.md eliminado.
    ) else (
        echo   [INFO] CLAUDE.md no encontrado. Nada que restaurar.
    )
    echo.
)

echo =====================================================
echo   Team Brain desinstalado correctamente.
echo =====================================================
echo.
echo   Docker, Node.js y Claude Code permanecen instalados.
echo   Reinicia Claude Code para que los cambios tomen efecto.
echo.
endlocal
exit /b 0

:END_FAILURE
echo.
echo   [FALLO] Setup incompleto. Revisa los errores arriba.
echo.
endlocal
exit /b 1

:END_SUCCESS
endlocal
exit /b 0
