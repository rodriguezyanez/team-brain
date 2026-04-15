# =============================================================
# brain-sync.ps1 — Sincroniza memorias pendientes con Neo4j
#
# Uso:
#   .\brain-sync.ps1
#
# Cuando Neo4j no estaba disponible, CLAUDE.md guia a Claude para
# guardar memorias localmente en:
#   %USERPROFILE%\.claude\pending-memories.jsonl
#
# Este script lee ese archivo y sincroniza cada entrada con Neo4j.
# Las entradas exitosas se eliminan. Las fallidas se conservan.
# =============================================================

param(
    [string]$Neo4jUri    = "http://localhost:7474",
    [string]$Neo4jUser   = "neo4j",
    [string]$Neo4jPass   = "team-brain-2025",
    [string]$Neo4jDb     = "neo4j"
)

$QueueFile = Join-Path $env:USERPROFILE ".claude\pending-memories.jsonl"
$TxEndpoint = "$Neo4jUri/db/$Neo4jDb/tx/commit"
$AuthBytes  = [System.Text.Encoding]::UTF8.GetBytes("${Neo4jUser}:${Neo4jPass}")
$AuthHeader = "Basic " + [Convert]::ToBase64String($AuthBytes)

# ── Helpers ──────────────────────────────────────────────────

function Test-Neo4j {
    try {
        $resp = Invoke-WebRequest -Uri "$Neo4jUri/db/$Neo4jDb" `
            -Headers @{ Authorization = $AuthHeader } `
            -TimeoutSec 5 -ErrorAction Stop
        return $resp.StatusCode -lt 400
    } catch {
        return $false
    }
}

function Invoke-Cypher {
    param([string]$Statement, [hashtable]$Parameters = @{})
    $body = @{
        statements = @(@{
            statement  = $Statement
            parameters = $Parameters
        })
    } | ConvertTo-Json -Depth 10 -Compress

    $resp = Invoke-RestMethod -Uri $TxEndpoint `
        -Method Post `
        -Headers @{ Authorization = $AuthHeader; "Content-Type" = "application/json" } `
        -Body $body `
        -ErrorAction Stop

    if ($resp.errors -and $resp.errors.Count -gt 0) {
        throw "Neo4j error: $($resp.errors[0].message)"
    }
    return $resp
}

function Sync-Memory {
    param($Entry)
    # Appenda observaciones sin duplicar
    $cypher = @"
MERGE (e:Entity {name: `$name})
SET e.entityType = `$entityType
WITH e, `$observations AS newObs
CALL {
  WITH e, newObs
  UNWIND newObs AS obs
  WITH e, obs
  WHERE NOT obs IN coalesce(e.observations, [])
  SET e.observations = coalesce(e.observations, []) + [obs]
}
RETURN e.name AS name
"@
    Invoke-Cypher -Statement $cypher -Parameters @{
        name         = $Entry.name
        entityType   = $Entry.entityType
        observations = @($Entry.observations)
    } | Out-Null
}

function Sync-Connection {
    param($Entry)
    # La relacion dinamica se construye en el string Cypher
    $relType = $Entry.relationType -replace '[^A-Z0-9_]', '_'
    $cypher = "MATCH (a:Entity {name: `$from}), (b:Entity {name: `$to}) MERGE (a)-[:$relType]->(b)"
    Invoke-Cypher -Statement $cypher -Parameters @{
        from = $Entry.from
        to   = $Entry.to
    } | Out-Null
}

# ── Main ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "Team Brain — Sincronizacion de memoria pendiente" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $QueueFile)) {
    Write-Host "[OK] No hay memorias pendientes." -ForegroundColor Green
    Write-Host ""
    exit 0
}

$lines = Get-Content $QueueFile -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }

if ($lines.Count -eq 0) {
    Write-Host "[OK] No hay memorias pendientes." -ForegroundColor Green
    Remove-Item $QueueFile -Force
    Write-Host ""
    exit 0
}

Write-Host "   Memorias en cola: $($lines.Count)"
Write-Host ""

# Verificar Neo4j
Write-Host "   Verificando conexion con Neo4j..."
if (-not (Test-Neo4j)) {
    Write-Host "[ERROR] Neo4j no responde en $Neo4jUri" -ForegroundColor Red
    Write-Host "        Ejecuta 'brain.bat up' y vuelve a intentarlo." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Host "   Neo4j disponible." -ForegroundColor Green
Write-Host ""

$ok      = 0
$failed  = 0
$pending = @()

foreach ($line in $lines) {
    try {
        $entry = $line | ConvertFrom-Json
        switch ($entry.type) {
            "memory"     { Sync-Memory     -Entry $entry }
            "connection" { Sync-Connection -Entry $entry }
            default      { throw "Tipo desconocido: $($entry.type)" }
        }
        $ok++
        $label = if ($entry.type -eq "memory") { $entry.name } else { "$($entry.from) -> $($entry.to)" }
        Write-Host "   [OK] $label" -ForegroundColor Green
    } catch {
        $failed++
        $pending += $line
        $label = try { ($line | ConvertFrom-Json).name } catch { "?" }
        Write-Host "   [FAIL] $label — $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Reescribir el archivo solo con las entradas fallidas
if ($pending.Count -gt 0) {
    $pending | Set-Content $QueueFile -Encoding UTF8
} else {
    Remove-Item $QueueFile -Force
}

Write-Host ""
Write-Host "   Sincronizadas: $ok  |  Fallidas (conservadas): $failed" -ForegroundColor Cyan
Write-Host ""

if ($failed -gt 0) {
    Write-Host "   Las entradas fallidas permanecen en:" -ForegroundColor Yellow
    Write-Host "   $QueueFile" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "[OK] Toda la memoria pendiente fue sincronizada con Neo4j." -ForegroundColor Green
Write-Host ""
exit 0
