# =============================================================
# brain-import.ps1 — Importa y mergea un export JSON en Neo4j
#
# Uso:
#   .\brain-import.ps1 -InputFile "teambrain-export-dev01-20260416.json"
#
# Estrategia de merge:
#   - Entidades: MERGE por name. Agrega solo las observaciones
#     que no existan ya en el master. No sobreescribe nada.
#   - Relaciones: MERGE por (from, relationType, to).
#     Solo crea las que no existan.
#   - entityType: se preserva el del master si ya existe.
# =============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    [string]$Neo4jUri  = "http://localhost:7474",
    [string]$Neo4jUser = "neo4j",
    [string]$Neo4jPass = "team-brain-2025",
    [string]$Neo4jDb   = "neo4j"
)

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
    } | ConvertTo-Json -Depth 20 -Compress

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

# Trae las observaciones actuales de una entidad en el master
function Get-MasterObservations {
    param([string]$EntityName)
    $resp = Invoke-Cypher `
        -Statement "MATCH (e:Entity {name: `$name}) RETURN coalesce(e.observations, []) AS observations" `
        -Parameters @{ name = $EntityName }

    if ($resp.results[0].data.Count -eq 0) { return @() }
    $raw = $resp.results[0].data[0].row[0]
    if ($null -eq $raw) { return @() }
    return @($raw)
}

# ── Main ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "Team Brain -- Importacion y merge de grafo" -ForegroundColor Cyan
Write-Host ""

# Validar archivo
if (-not (Test-Path $InputFile)) {
    Write-Host "[ERROR] Archivo no encontrado: $InputFile" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Cargar JSON
try {
    $data = Get-Content $InputFile -Encoding UTF8 -Raw | ConvertFrom-Json
} catch {
    Write-Host "[ERROR] No se pudo parsear el JSON: $_" -ForegroundColor Red
    exit 1
}

$meta = $data.meta
Write-Host "   Archivo    : $InputFile"
Write-Host "   Exportado  : $($meta.exportedAt)"
Write-Host "   Origen     : $($meta.exportedBy) / $($meta.exportedByUser)"
Write-Host "   Entidades  : $($meta.entityCount)"
Write-Host "   Relaciones : $($meta.connectionCount)"
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

# ── Merge de entidades ────────────────────────────────────────

Write-Host "   Procesando entidades..." -ForegroundColor Cyan
$entNew  = 0
$entUpd  = 0
$entSkip = 0
$obsAdded = 0

foreach ($entity in $data.entities) {
    try {
        $masterObs = Get-MasterObservations -EntityName $entity.name
        $incomingObs = if ($entity.observations) { @($entity.observations) } else { @() }

        # Calcular observaciones que faltan en el master
        $newObs = $incomingObs | Where-Object { $_ -notin $masterObs }

        if ($masterObs.Count -eq 0) {
            # Entidad nueva: crear con todas sus observaciones
            Invoke-Cypher `
                -Statement "MERGE (e:Entity {name: `$name}) SET e.entityType = `$entityType, e.observations = `$observations" `
                -Parameters @{
                    name         = $entity.name
                    entityType   = if ($entity.entityType) { $entity.entityType } else { "" }
                    observations = $incomingObs
                } | Out-Null
            $entNew++
            $obsAdded += $incomingObs.Count
            Write-Host "   [NEW]  $($entity.name)" -ForegroundColor Green
        } elseif ($newObs.Count -gt 0) {
            # Entidad existente con observaciones nuevas: agregar solo las que faltan
            Invoke-Cypher `
                -Statement @"
MATCH (e:Entity {name: `$name})
WITH e, `$newObs AS newObs
UNWIND newObs AS obs
WITH e, obs
WHERE NOT obs IN coalesce(e.observations, [])
SET e.observations = coalesce(e.observations, []) + [obs]
"@ `
                -Parameters @{
                    name   = $entity.name
                    newObs = @($newObs)
                } | Out-Null
            $entUpd++
            $obsAdded += $newObs.Count
            Write-Host "   [UPD]  $($entity.name) (+$($newObs.Count) obs)" -ForegroundColor Yellow
        } else {
            $entSkip++
        }
    } catch {
        Write-Host "   [FAIL] $($entity.name): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "   Entidades nuevas    : $entNew" -ForegroundColor Green
Write-Host "   Entidades actualizadas: $entUpd" -ForegroundColor Yellow
Write-Host "   Entidades sin cambios : $entSkip"
Write-Host "   Observaciones agregadas: $obsAdded" -ForegroundColor Green
Write-Host ""

# ── Merge de relaciones ───────────────────────────────────────

Write-Host "   Procesando relaciones..." -ForegroundColor Cyan
$relNew  = 0
$relSkip = 0

foreach ($conn in $data.connections) {
    try {
        # Sanitizar relationType: solo A-Z, 0-9, _
        $relType = $conn.relationType -replace '[^A-Z0-9_]', '_'

        $checkResp = Invoke-Cypher `
            -Statement "MATCH (a:Entity {name: `$from})-[r:$relType]->(b:Entity {name: `$to}) RETURN count(r) AS cnt" `
            -Parameters @{ from = $conn.from; to = $conn.to }

        $exists = $checkResp.results[0].data[0].row[0] -gt 0

        if (-not $exists) {
            Invoke-Cypher `
                -Statement "MATCH (a:Entity {name: `$from}), (b:Entity {name: `$to}) MERGE (a)-[:$relType]->(b)" `
                -Parameters @{ from = $conn.from; to = $conn.to } | Out-Null
            $relNew++
            Write-Host "   [NEW]  $($conn.from) -[$relType]-> $($conn.to)" -ForegroundColor Green
        } else {
            $relSkip++
        }
    } catch {
        Write-Host "   [FAIL] $($conn.from) -> $($conn.to): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "   Relaciones nuevas       : $relNew" -ForegroundColor Green
Write-Host "   Relaciones ya existentes: $relSkip"
Write-Host ""

# ── Resumen ───────────────────────────────────────────────────

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   Import completado." -ForegroundColor Green
Write-Host "   Entidades: $entNew nuevas, $entUpd actualizadas, $entSkip sin cambios"
Write-Host "   Relaciones: $relNew nuevas, $relSkip sin cambios"
Write-Host "   Observaciones agregadas: $obsAdded"
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
