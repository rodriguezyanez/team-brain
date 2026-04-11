# =============================================================
# brain.ps1 — Comandos rapidos para Team Brain en Windows
#
# Uso:
#   .\brain.ps1 up       -> levantar Neo4j
#   .\brain.ps1 down     -> detener Neo4j
#   .\brain.ps1 restart  -> reiniciar Neo4j
#   .\brain.ps1 status   -> ver estado del contenedor
#   .\brain.ps1 logs     -> ver logs en vivo
#   .\brain.ps1 browser  -> abrir Neo4j Browser
#   .\brain.ps1 mcp      -> registrar MCP en Claude Code
#
# Si PowerShell bloquea la ejecucion, corre primero:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# =============================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("up","down","restart","status","logs","browser","mcp","")]
    [string]$Action = ""
)

if ($Action -eq "") {
    Write-Host ""
    Write-Host "Team Brain -- Comandos disponibles:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  .\brain.ps1 up       Levantar Neo4j"
    Write-Host "  .\brain.ps1 down     Detener Neo4j (datos persisten)"
    Write-Host "  .\brain.ps1 restart  Reiniciar Neo4j"
    Write-Host "  .\brain.ps1 status   Ver estado del contenedor"
    Write-Host "  .\brain.ps1 logs     Ver logs en vivo"
    Write-Host "  .\brain.ps1 browser  Abrir Neo4j Browser"
    Write-Host "  .\brain.ps1 mcp      Registrar MCP en Claude Code"
    Write-Host ""
    exit 0
}

switch ($Action) {

    "up" {
        Write-Host ""
        Write-Host "Levantando Team Brain..."
        docker compose up -d
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Neo4j corriendo." -ForegroundColor Green
            Write-Host "     Browser : http://localhost:7474"
            Write-Host "     Bolt    : bolt://localhost:7687"
        } else {
            Write-Host "[ERROR] Fallo al levantar. Verifica que Docker Desktop este abierto." -ForegroundColor Red
        }
    }

    "down" {
        Write-Host ""
        Write-Host "Deteniendo Team Brain..."
        docker compose down
        Write-Host "[OK] Contenedor detenido. Los datos persisten en los volumenes." -ForegroundColor Green
    }

    "restart" {
        Write-Host ""
        Write-Host "Reiniciando Neo4j..."
        docker compose restart neo4j
        Write-Host "[OK] Reiniciado." -ForegroundColor Green
    }

    "status" {
        Write-Host ""
        docker compose ps
    }

    "logs" {
        Write-Host ""
        Write-Host "Logs en vivo (Ctrl+C para salir)..."
        Write-Host ""
        docker compose logs -f neo4j
    }

    "browser" {
        Write-Host ""
        Write-Host "Abriendo Neo4j Browser..."
        Start-Process "http://localhost:7474"
    }

    "mcp" {
        Write-Host ""
        Write-Host "Registrando MCP team-brain en Claude Code..."
        Write-Host ""
        Write-Host "IMPORTANTE: Reemplaza la password si la cambiaste en docker-compose.yml" -ForegroundColor Yellow
        Write-Host ""

        $mcpConfig = '{"command":"npx","args":["-y","@knowall-ai/mcp-neo4j-agent-memory"],"env":{"NEO4J_URI":"bolt://localhost:7687","NEO4J_USERNAME":"neo4j","NEO4J_PASSWORD":"team-brain-2025","NEO4J_DATABASE":"neo4j"}}'

        claude mcp add-json "team-brain" $mcpConfig

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] MCP registrado. Verificando..." -ForegroundColor Green
            claude mcp list
        } else {
            Write-Host ""
            Write-Host "[ERROR] Fallo el registro del MCP." -ForegroundColor Red
            Write-Host "        Asegurate de tener Claude Code instalado:"
            Write-Host "        npm install -g @anthropic-ai/claude-code"
        }
    }
}

Write-Host ""