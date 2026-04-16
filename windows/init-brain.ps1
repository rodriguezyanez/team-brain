# =============================================================
# init-brain.ps1 — Inicializa Team Brain en Neo4j
# Uso: .\init-brain.ps1
#      .\init-brain.ps1 -Host 192.168.1.50 -Password "mi-password"
# =============================================================

param(
    [string]$Neo4jHost = "localhost",
    [string]$Neo4jPort = "7474",
    [string]$User      = "neo4j",
    [string]$Password  = "team-brain-2025"
)

$BaseUrl = "http://${Neo4jHost}:${Neo4jPort}"
$Creds   = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${User}:${Password}"))
$Headers = @{ "Content-Type" = "application/json"; "Authorization" = "Basic $Creds" }

function Write-Step($msg) { Write-Host "  -> $msg" -NoNewline }
function Write-Ok        { Write-Host " [OK]"  -ForegroundColor Green }
function Write-Warn($c)  { Write-Host " [WARN] HTTP $c" -ForegroundColor Yellow }

function Invoke-Cypher($db, $query, $desc) {
    Write-Step $desc
    $body = '{"statements":[{"statement":"' + $query + '"}]}'
    try {
        $r = Invoke-WebRequest -Uri "$BaseUrl/db/$db/tx/commit" `
            -Method POST -Headers $Headers -Body $body `
            -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -in 200,201) { Write-Ok } else { Write-Warn $r.StatusCode }
    } catch { Write-Warn $_.Exception.Response.StatusCode.value__ }
}

# ── Banner ────────────────────────────────────────────────────
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Team Brain -- Inicializacion de base de datos"      -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Host: $BaseUrl"
Write-Host ""

# ── Esperar Neo4j ─────────────────────────────────────────────
Write-Host "Esperando que Neo4j este disponible..."
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $r = Invoke-WebRequest -Uri "$BaseUrl/db/neo4j/tx/commit" `
            -Method POST -Headers $Headers `
            -Body '{"statements":[{"statement":"RETURN 1"}]}' `
            -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -in 200,201) { $ready = $true; break }
    } catch {}
    Write-Host "  Intento $i/30..."
    Start-Sleep -Seconds 3
}
if (-not $ready) { Write-Host "[ERROR] Neo4j no respondio." -ForegroundColor Red; exit 1 }
Write-Host "  Neo4j listo." -ForegroundColor Green
Write-Host ""

# ── Detectar edicion (Community vs Enterprise) ────────────────
Write-Host "Verificando edicion de Neo4j..."
$useDb = "neo4j"   # default para Community

try {
    $edBody = '{"statements":[{"statement":"CALL dbms.components() YIELD edition RETURN edition"}]}'
    $edResp = Invoke-WebRequest -Uri "$BaseUrl/db/system/tx/commit" `
        -Method POST -Headers $Headers -Body $edBody `
        -UseBasicParsing -ErrorAction Stop
    if ($edResp.Content -match "enterprise") {
        $useDb = "memory"
        Write-Host "  Edicion Enterprise detectada. Creando base de datos 'memory'..."
        Invoke-Cypher "system" "CREATE DATABASE memory IF NOT EXISTS" "Crear DB memory"
        Write-Host "  Esperando que la DB memory quede online..."
        Start-Sleep -Seconds 8
    } else {
        Write-Host "  Edicion Community detectada." -ForegroundColor Yellow
        Write-Host "  Community no soporta multiples bases de datos." -ForegroundColor Yellow
        Write-Host "  Usando la base de datos por defecto: 'neo4j'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  No se pudo detectar edicion. Usando 'neo4j'." -ForegroundColor Yellow
}
Write-Host ""

# ── Constraints e indices ─────────────────────────────────────
Write-Host "Creando constraints e indices en DB: $useDb..."
Invoke-Cypher $useDb "CREATE CONSTRAINT entity_name IF NOT EXISTS FOR (e:Entity) REQUIRE e.name IS UNIQUE"        "Constraint Entity.name unico"
Invoke-Cypher $useDb "CREATE INDEX entity_type_idx IF NOT EXISTS FOR (e:Entity) ON (e.entityType)"               "Indice Entity.entityType"
Invoke-Cypher $useDb "CREATE INDEX observation_idx IF NOT EXISTS FOR (o:Observation) ON (o.content)"             "Indice Observation.content"
Invoke-Cypher $useDb "CREATE INDEX entity_created_idx IF NOT EXISTS FOR (e:Entity) ON (e.createdAt)"             "Indice Entity.createdAt"

# ── Nodos base ────────────────────────────────────────────────
Write-Host ""
Write-Host "Creando nodos base del equipo..."
Invoke-Cypher $useDb "MERGE (t:Entity {name: 'Team', entityType: 'Organization'}) SET t.createdAt = datetime(), t.description = 'Equipo de desarrollo'" "Nodo Team"
Invoke-Cypher $useDb "MERGE (p:Entity {name: 'Architecture', entityType: 'Topic'}) SET p.createdAt = datetime()" "Nodo Architecture"
Invoke-Cypher $useDb "MERGE (d:Entity {name: 'Decisions', entityType: 'Topic'}) SET d.createdAt = datetime()"    "Nodo Decisions"
Invoke-Cypher $useDb "MERGE (c:Entity {name: 'Conventions', entityType: 'Topic'}) SET c.createdAt = datetime()"  "Nodo Conventions"

# ── Resultado ─────────────────────────────────────────────────
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Team Brain inicializado correctamente"               -ForegroundColor Green
Write-Host ""
Write-Host "  Neo4j Browser : $BaseUrl"
Write-Host "  Usuario       : $User"
Write-Host "  Base de datos : $useDb"
Write-Host "  Bolt URI      : bolt://${Neo4jHost}:7687"
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Proximo paso — ejecuta en tu terminal:"
Write-Host ""
Write-Host "  brain.bat mcp"
Write-Host ""
Write-Host "  (o manualmente):"
Write-Host "  claude mcp add-json ""team-brain"" '{""command"":""npx"",""args"":[""-y"",""@knowall-ai/mcp-neo4j-agent-memory""],""env"":{""NEO4J_URI"":""bolt://localhost:7687"",""NEO4J_USERNAME"":""neo4j"",""NEO4J_PASSWORD"":""$Password"",""NEO4J_DATABASE"":""$useDb""}}'"
Write-Host ""