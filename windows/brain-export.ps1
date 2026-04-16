# =============================================================
# brain-export.ps1 — Exporta todo el grafo de Neo4j a JSON
#
# Uso:
#   .\brain-export.ps1 [-OutputFile "export.json"]
#
# Genera un archivo JSON con todas las entidades y relaciones
# del grafo local. El archivo puede ser compartido con otro dev
# para consolidar informacion con brain-import.ps1.
# =============================================================

param(
    [string]$OutputFile = "",
    [string]$Neo4jUri   = "http://localhost:7474",
    [string]$Neo4jUser  = "neo4j",
    [string]$Neo4jPass  = "team-brain-2025",
    [string]$Neo4jDb    = "neo4j"
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
    param([string]$Statement)
    $body = @{
        statements = @(@{ statement = $Statement })
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

# ── Resolucion del archivo de salida ─────────────────────────

if ($OutputFile -eq "") {
    $timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
    $machineName = $env:COMPUTERNAME.ToLower()
    $OutputFile = "teambrain-export-${machineName}-${timestamp}.json"
}

# ── Main ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "Team Brain -- Exportacion de grafo" -ForegroundColor Cyan
Write-Host ""

Write-Host "   Verificando conexion con Neo4j..."
if (-not (Test-Neo4j)) {
    Write-Host "[ERROR] Neo4j no responde en $Neo4jUri" -ForegroundColor Red
    Write-Host "        Ejecuta 'brain.bat up' y vuelve a intentarlo." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Host "   Neo4j disponible." -ForegroundColor Green
Write-Host ""

# ── Exportar entidades ────────────────────────────────────────

Write-Host "   Exportando entidades..."
$entitiesResp = Invoke-Cypher -Statement "MATCH (e:Entity) RETURN e.name AS name, e.entityType AS entityType, e.observations AS observations ORDER BY e.name"

$entities = @()
foreach ($row in $entitiesResp.results[0].data) {
    $cols = $entitiesResp.results[0].columns
    $record = @{}
    for ($i = 0; $i -lt $cols.Count; $i++) { $record[$cols[$i]] = $row.row[$i] }

    $entities += @{
        name        = $record["name"]
        entityType  = if ($record["entityType"]) { $record["entityType"] } else { "" }
        observations = if ($record["observations"]) { @($record["observations"]) } else { @() }
    }
}
Write-Host "   Entidades encontradas: $($entities.Count)" -ForegroundColor Green

# ── Exportar relaciones ───────────────────────────────────────

Write-Host "   Exportando relaciones..."
$connectionsResp = Invoke-Cypher -Statement "MATCH (a:Entity)-[r]->(b:Entity) RETURN a.name AS from, type(r) AS relationType, b.name AS to ORDER BY a.name, type(r), b.name"

$connections = @()
foreach ($row in $connectionsResp.results[0].data) {
    $cols = $connectionsResp.results[0].columns
    $record = @{}
    for ($i = 0; $i -lt $cols.Count; $i++) { $record[$cols[$i]] = $row.row[$i] }

    $connections += @{
        from         = $record["from"]
        relationType = $record["relationType"]
        to           = $record["to"]
    }
}
Write-Host "   Relaciones encontradas: $($connections.Count)" -ForegroundColor Green
Write-Host ""

# ── Construir y escribir JSON ─────────────────────────────────

$export = @{
    meta = @{
        exportedAt          = (Get-Date -Format "o")
        exportedBy          = $env:COMPUTERNAME
        exportedByUser      = $env:USERNAME
        neo4jUri            = $Neo4jUri
        teamBrainVersion    = "3.0"
        entityCount         = $entities.Count
        connectionCount     = $connections.Count
    }
    entities    = $entities
    connections = $connections
}

$json = $export | ConvertTo-Json -Depth 20
$encWithBOM = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText((Resolve-Path ".").Path + "\" + $OutputFile, $json, $encWithBOM)

Write-Host "   [OK] Export guardado en: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "   Compartilo con el responsable del master y ejecuta:" -ForegroundColor Yellow
Write-Host "     brain.bat import $OutputFile" -ForegroundColor Yellow
Write-Host ""
