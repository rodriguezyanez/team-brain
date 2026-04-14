# =============================================================
# setup.ps1 — Instalador unificado de Team Brain (PowerShell)
#
# Uso:
#   .\setup.ps1
#
# Orquesta todo el setup de primer uso en un solo comando:
#   1. Verifica prerequisitos
#   2. Levanta Neo4j
#   3. Inicializa la base de datos
#   4. Carga la arquitectura de referencia KLAP BYSF
#   5. Registra el MCP en Claude Code
#   6. Instala CLAUDE.md en el perfil del usuario
#
# Si PowerShell bloquea la ejecucion, corre primero:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# =============================================================

$ErrorActionPreference = "Continue"

# ── Helpers de output ─────────────────────────────────────────
function Write-Step { param([string]$msg) Write-Host "`n── $msg " -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$msg) Write-Host "  [ERROR] $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "  [INFO] $msg" -ForegroundColor Gray }
function Write-Skip { param([string]$msg) Write-Host "  [SKIP] $msg" -ForegroundColor DarkGray }

# ── Banner ────────────────────────────────────────────────────
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Team Brain -- Instalador unificado" -ForegroundColor Cyan
Write-Host "  KLAP BYSF Knowledge Graph Setup" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================
# PASO 0: Detectar password desde docker-compose.yml
# =============================================================
$neo4jPass = "team-brain-2025"

if (Test-Path "docker-compose.yml") {
    $authLine = Select-String -Path "docker-compose.yml" -Pattern "NEO4J_AUTH" | Select-Object -First 1
    if ($authLine) {
        $match = [regex]::Match($authLine.Line, "neo4j/(.+)")
        if ($match.Success) {
            $neo4jPass = $match.Groups[1].Value.Trim()
        }
    }
}
Write-Info "Password Neo4j detectada desde docker-compose.yml: $neo4jPass"

# =============================================================
# PASO 1: Verificar prerequisitos
# =============================================================
Write-Step "PASO 1: Verificando prerequisitos ──────────────────"
Write-Host ""

$errors = 0
$claudeAvailable = $false

# -- Docker --
try {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Docker Desktop corriendo"
    } else {
        Write-Err "Docker Desktop no esta corriendo."
        Write-Host "         Abre Docker Desktop y vuelve a ejecutar setup.ps1" -ForegroundColor Red
        $errors++
    }
} catch {
    Write-Err "Docker no encontrado. Instala Docker Desktop."
    $errors++
}

# -- Docker Compose --
try {
    docker compose version 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "docker compose disponible"
    } else {
        Write-Err "docker compose no disponible. Actualiza Docker Desktop."
        $errors++
    }
} catch {
    Write-Err "docker compose no disponible."
    $errors++
}

# -- Node.js >= 18 --
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
        if ($majorVersion -ge 18) {
            Write-OK "Node.js $majorVersion instalado"
        } else {
            Write-Warn "Node.js $majorVersion detectado. Se recomienda Node.js 18+."
        }
    } else {
        Write-Err "Node.js no encontrado. Instala Node.js 18+ desde https://nodejs.org"
        $errors++
    }
} catch {
    Write-Err "Node.js no encontrado. Instala Node.js 18+ desde https://nodejs.org"
    $errors++
}

# -- curl --
try {
    $curlPath = Get-Command curl -ErrorAction SilentlyContinue
    if ($curlPath) {
        Write-OK "curl disponible"
    } else {
        Write-Err "curl no encontrado. Es necesario para inicializar Neo4j."
        $errors++
    }
} catch {
    Write-Err "curl no encontrado."
    $errors++
}

# -- Claude Code --
try {
    $claudePath = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudePath) {
        Write-OK "Claude Code instalado"
        $claudeAvailable = $true
    } else {
        Write-Warn "Claude Code (claude CLI) no encontrado."
        Write-Host "         El MCP no se podra registrar automaticamente." -ForegroundColor Yellow
        Write-Host "         Instala con: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    }
} catch {
    Write-Warn "Claude Code no encontrado."
}

if ($errors -gt 0) {
    Write-Host ""
    Write-Err "Se encontraron $errors error(es) critico(s). Corrigelos y vuelve a ejecutar."
    Write-Host ""
    exit 1
}

Write-Host ""
Write-OK "Todos los prerequisitos OK."

# =============================================================
# PASO 2: Levantar Neo4j
# =============================================================
Write-Step "PASO 2: Levantando Neo4j ────────────────────────────"
Write-Host ""

docker compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Err "No se pudo levantar Neo4j."
    Write-Host "         Verifica docker-compose.yml y que Docker Desktop este abierto." -ForegroundColor Red
    exit 1
}
Write-OK "Contenedor Neo4j iniciado."

# =============================================================
# PASO 3: Inicializar base de datos (via init-brain.bat)
# =============================================================
Write-Step "PASO 3: Inicializando base de datos ─────────────────"
Write-Host ""

if (Test-Path "init-brain.ps1") {
    & .\init-brain.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "init-brain.ps1 fallo."
        exit 1
    }
} elseif (Test-Path "init-brain.bat") {
    cmd /c init-brain.bat
    if ($LASTEXITCODE -ne 0) {
        Write-Err "init-brain.bat fallo."
        exit 1
    }
} else {
    Write-Err "No se encontro init-brain.ps1 ni init-brain.bat"
    exit 1
}

# =============================================================
# PASO 4: Cargar arquitectura de referencia KLAP BYSF
# =============================================================
Write-Step "PASO 4: Cargando arquitectura KLAP BYSF ─────────────"
Write-Host ""

if (Test-Path "enrich-brain.bat") {
    cmd /c enrich-brain.bat
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "enrich-brain.bat termino con errores. Continuando..."
    } else {
        Write-OK "Arquitectura de referencia cargada en Neo4j."
    }
} else {
    Write-Skip "enrich-brain.bat no encontrado. Saltando enriquecimiento."
}

# =============================================================
# PASO 5: Registrar MCP en Claude Code
# =============================================================
Write-Step "PASO 5: Registrando MCP en Claude Code ──────────────"
Write-Host ""

if ($claudeAvailable) {
    $mcpConfig = "{`"command`":`"npx`",`"args`":[`"-y`",`"@knowall-ai/mcp-neo4j-agent-memory`"],`"env`":{`"NEO4J_URI`":`"bolt://localhost:7687`",`"NEO4J_USERNAME`":`"neo4j`",`"NEO4J_PASSWORD`":`"$neo4jPass`",`"NEO4J_DATABASE`":`"neo4j`"}}"

    claude mcp add-json "team-brain" $mcpConfig --scope user 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "MCP team-brain registrado con scope user."
    } else {
        Write-Info "MCP ya registrado o error en registro. Verifica con: claude mcp list"
    }
} else {
    Write-Skip "Claude Code no disponible. Registra el MCP manualmente con: .\brain.ps1 mcp"
}

# =============================================================
# PASO 5b: Registrar Context7 MCP (opcional — docs en tiempo real)
# =============================================================
Write-Step "PASO 5b: Registrando Context7 MCP (opcional) ────────"
Write-Host ""

if ($claudeAvailable) {
    $ctx7Config = '{"command":"npx","args":["-y","@upstash/context7-mcp"]}'
    claude mcp add-json "context7" $ctx7Config --scope user 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Context7 registrado. Agrega 'use context7' a tus prompts para docs en tiempo real."
    } else {
        Write-Info "Context7 ya registrado o no disponible. Continua..."
    }
} else {
    Write-Skip "Claude Code no disponible. Registra Context7 con: .\install-context7.ps1"
}

# =============================================================
# PASO 5c: Registrar Sequential Thinking MCP
# =============================================================
Write-Step "PASO 5c: Registrando Sequential Thinking MCP ───────"
Write-Host ""

if ($claudeAvailable) {
    claude mcp add-json "sequential-thinking" '{"command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"]}' --scope user 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Sequential Thinking MCP registrado."
    } else {
        Write-Info "Sequential Thinking ya registrado o no disponible. Continua..."
    }
} else {
    Write-Skip "Claude Code no disponible. Registra Sequential Thinking manualmente."
}

# =============================================================
# PASO 5d: Instalar plugins de Claude Code
# (superpowers, context-mode, context7-plugin)
# Se configuran via settings.json — no via mcp add-json
# =============================================================
Write-Step "PASO 5d: Instalando plugins Claude Code ────────────"
Write-Host ""

$settingsPath = "$env:USERPROFILE\.claude\settings.json"

try {
    $settings = @{}
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
    }

    if (-not $settings.ContainsKey("enabledPlugins")) { $settings["enabledPlugins"] = @{} }
    $settings["enabledPlugins"]["superpowers@claude-plugins-official"] = $true
    $settings["enabledPlugins"]["context-mode@context-mode"] = $true
    $settings["enabledPlugins"]["context7@claude-plugins-official"] = $true
    $settings["enabledPlugins"]["code-simplifier@claude-plugins-official"] = $true
    $settings["enabledPlugins"]["code-review@claude-plugins-official"] = $true
    $settings["enabledPlugins"]["pr-review-toolkit@claude-plugins-official"] = $true
    $settings["enabledPlugins"]["commit-commands@claude-plugins-official"] = $true
    $settings["enabledPlugins"]["feature-dev@claude-plugins-official"] = $true
    $settings["enabledPlugins"]["claude-md-management@claude-plugins-official"] = $true

    if (-not $settings.ContainsKey("extraKnownMarketplaces")) { $settings["extraKnownMarketplaces"] = @{} }
    $settings["extraKnownMarketplaces"]["context-mode"] = @{
        source = @{ source = "github"; repo = "mksglu/context-mode" }
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-OK "Plugins registrados: superpowers, context-mode, context7, code-simplifier, code-review, pr-review-toolkit, commit-commands, feature-dev, claude-md-management"
} catch {
    Write-Warn "No se pudieron registrar los plugins: $_"
    Write-Warn "Instalalos manualmente en Claude Code."
}

Write-Info "Nota: Atlassian Rovo requiere autenticacion OAuth manual."
Write-Info "      Conecta tu cuenta en: https://claude.ai/settings/integrations"
Write-Host ""

# =============================================================
# PASO 6: Instalar skill files locales en Claude Code
# =============================================================
Write-Step "PASO 6: Instalando skills locales ──────────────────"
Write-Host ""

if (Test-Path "install-skills.ps1") {
    & .\install-skills.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "install-skills.ps1 terminó con errores. Continuando..."
    }
} elseif (Test-Path "install-skills.bat") {
    cmd /c install-skills.bat
} else {
    Write-Skip "install-skills.ps1 no encontrado. Saltando skills locales."
}

# =============================================================
# PASO 7: Instalar CLAUDE.md en el perfil del usuario
# =============================================================
Write-Step "PASO 7: Instalando CLAUDE.md ────────────────────────"
Write-Host ""

if (Test-Path "CLAUDE.md") {
    $claudeDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    $destPath = "$claudeDir\CLAUDE.md"
    if (Test-Path $destPath) {
        Write-Info "Ya existe $destPath"
        Copy-Item $destPath "$destPath.bak" -Force
        Write-Info "Backup creado: $destPath.bak"
    }

    Copy-Item "CLAUDE.md" $destPath -Force
    if ($?) {
        Write-OK "CLAUDE.md instalado en $destPath"
    } else {
        Write-Warn "No se pudo copiar CLAUDE.md. Copíalo manualmente."
    }
} else {
    Write-Skip "CLAUDE.md no encontrado en el directorio actual."
}

# =============================================================
# PASO 8: Guardian Angel hook pre-commit (opcional)
# =============================================================
Write-Step "PASO 8: Guardian Angel hook pre-commit (opcional) ──────"
Write-Host ""
Write-Host "  Para instalar el hook en tu proyecto:" -ForegroundColor White
Write-Host "    .\install-hooks.ps1 -ProjectDir C:\ruta\tu\proyecto" -ForegroundColor Yellow
Write-Host ""
Write-Host "  El hook revisara cada commit Java/Kotlin contra las reglas del equipo." -ForegroundColor White
Write-Host "  Bypass urgente: git commit --no-verify" -ForegroundColor White
Write-Host ""

# =============================================================
# RESUMEN FINAL
# =============================================================
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Team Brain instalado correctamente!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Neo4j Browser : http://localhost:7474"
Write-Host "  Usuario       : neo4j"
Write-Host "  Password      : $neo4jPass"
Write-Host "  Bolt URI      : bolt://localhost:7687"
Write-Host ""
Write-Host "  MCPs registrados:"
Write-Host "    team-brain, context7, sequential-thinking"
Write-Host "  Plugins registrados:"
Write-Host "    superpowers, context-mode, context7"
Write-Host "    code-simplifier, code-review, pr-review-toolkit"
Write-Host "    commit-commands, feature-dev, claude-md-management"
Write-Host "  Atlassian Rovo (OAuth manual): https://claude.ai/settings/integrations"
Write-Host ""
Write-Host "  Verificar conexion MCP:"
Write-Host "    claude mcp list"
Write-Host ""
Write-Host "  Verificar grafo en Neo4j Browser:"
Write-Host "    MATCH (n:Entity) RETURN n"
Write-Host ""
Write-Host "  Proximos pasos:" -ForegroundColor Cyan
Write-Host "    1. Abre Claude Code en tu proyecto"
Write-Host "    2. Escribe 'onboarding' para comenzar"
Write-Host "    3. Escribe 'nivel: dev' para activar tu nivel"
Write-Host ""
Write-Host "  Operacion diaria:"
Write-Host "    .\brain.ps1 up      <- levantar Neo4j"
Write-Host "    .\brain.ps1 down    <- detener Neo4j"
Write-Host "    .\brain.ps1 status  <- ver estado"
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
