# =============================================================
# install-context7.ps1 — Registra Context7 MCP en Claude Code
# Context7 provee documentacion en tiempo real de las librerias
# del stack: Spring Boot 3.5.11, Kafka, Resilience4j, WebClient
# =============================================================
param()

# Si PowerShell bloquea la ejecucion, ejecuta primero:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

Write-Host ""
Write-Host "=== Instalando Context7 MCP en Claude Code ===" -ForegroundColor Cyan
Write-Host ""

# --- 1. Verificar claude CLI ---
$claudeCmd = Get-Command "claude" -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Host "[ERROR] Claude CLI no encontrado. Instala Claude Code primero." -ForegroundColor Red
    Write-Host "[ERROR]   https://claude.ai/code" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Claude CLI encontrado: $($claudeCmd.Source)" -ForegroundColor Green

# --- 2. Verificar npx ---
$npxCmd = Get-Command "npx" -ErrorAction SilentlyContinue
if (-not $npxCmd) {
    Write-Host "[ERROR] npx no encontrado. Instala Node.js primero." -ForegroundColor Red
    Write-Host "[ERROR]   https://nodejs.org" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] npx encontrado: $($npxCmd.Source)" -ForegroundColor Green

Write-Host ""
Write-Host "[INFO] Registrando Context7 MCP (scope: user)..." -ForegroundColor Cyan
Write-Host ""

# --- 3. Registrar el MCP ---
$mcpJson = '{"command":"npx","args":["-y","@upstash/context7-mcp"]}'

try {
    $result = & claude mcp add-json "context7" $mcpJson --scope user 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] El comando retorno codigo $LASTEXITCODE." -ForegroundColor Yellow
        Write-Host "[WARN] Si context7 ya estaba registrado, puede ignorarse." -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Context7 MCP registrado correctamente." -ForegroundColor Green
    }
    if ($result) {
        Write-Host $result
    }
} catch {
    Write-Host "[ERROR] Fallo el registro de Context7 MCP: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# --- 4. Verificar con mcp list ---
Write-Host "[INFO] MCPs registrados actualmente:" -ForegroundColor Cyan
Write-Host "-----------------------------------------------"
& claude mcp list
Write-Host "-----------------------------------------------"

Write-Host ""
Write-Host "[OK] === Instalacion completada ===" -ForegroundColor Green
Write-Host ""
Write-Host "[INFO] Como usar Context7 en Claude Code:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Agrega 'use context7' a tus prompts para obtener" -ForegroundColor White
Write-Host "  docs de la version exacta de las librerias del stack." -ForegroundColor White
Write-Host ""
Write-Host "  Ejemplo:" -ForegroundColor Yellow
Write-Host "  'use context7, como configuro Resilience4j 2.2.0" -ForegroundColor Yellow
Write-Host "   con Spring Boot 3.5.11?'" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Otros ejemplos:" -ForegroundColor Yellow
Write-Host "  - 'use context7, como uso WebClient con retry en Spring Boot 3.5.11?'" -ForegroundColor Yellow
Write-Host "  - 'use context7, configuracion de Kafka consumer con Spring 3.5.11'" -ForegroundColor Yellow
Write-Host "  - 'use context7, anotaciones de Resilience4j para circuit breaker'" -ForegroundColor Yellow
Write-Host ""
