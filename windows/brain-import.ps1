# =============================================================
# brain-import.ps1 — Importa y mergea un export JSON en Neo4j
#
# Uso:
#   .\brain-import.ps1 -InputFile "teambrain-export-dev01-20260416.json"
#
# Estrategia de merge (nunca sobreescribe, solo agrega):
#   - Entidad nueva     -> se crea con todas sus propiedades
#   - Entidad existente -> se agregan solo las propiedades (keys)
#                         que no existan en el master
#   - Relaciones        -> MERGE por (from, relationType, to)
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
        $resp = Invoke-WebRequest -Uri "$Neo4jUri/" `
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

# Retorna las propiedades actuales de una entidad en el master,
# o $null si la entidad no existe.
function Get-MasterProperties {
    param([string]$EntityName)
    $resp = Invoke-Cypher `
        -Statement "MATCH (e:Entity {name: `$name}) RETURN properties(e) AS props" `
        -Parameters @{ name = $EntityName }

    if ($resp.results[0].data.Count -eq 0) { return $null }
    return $resp.results[0].data[0].row[0]
}

# Convierte PSCustomObject a Hashtable
function ConvertTo-FlatHashtable {
    param($obj)
    if ($null -eq $obj) { return @{} }
    $ht = @{}
    foreach ($prop in $obj.PSObject.Properties) {
        $ht[$prop.Name] = $prop.Value
    }
    return $ht
}

# ── Main ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "Team Brain -- Importacion y merge de grafo" -ForegroundColor Cyan
Write-Host ""

# ── Validaciones ─────────────────────────────────────────────

if (-not (Test-Path $InputFile)) {
    Write-Host "[ERROR] Archivo no encontrado: $InputFile" -ForegroundColor Red
    Write-Host ""
    exit 1
}

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
$entNew     = 0
$entUpd     = 0
$entSkip    = 0
$propsAdded = 0

foreach ($entity in $data.entities) {
    try {
        $masterRaw   = Get-MasterProperties -EntityName $entity.name
        $masterProps = ConvertTo-FlatHashtable $masterRaw

        # Soporta formato nuevo (properties) y formato legacy (campos directos)
        if ($entity.properties) {
            $incomingProps = ConvertTo-FlatHashtable $entity.properties
        } else {
            $incomingProps = @{ name = $entity.name; entityType = $entity.entityType }
        }

        if ($null -eq $masterRaw) {
            # Entidad nueva: crear con todas sus propiedades
            Invoke-Cypher `
                -Statement "MERGE (e:Entity {name: `$name}) SET e += `$props" `
                -Parameters @{
                    name  = $entity.name
                    props = $incomingProps
                } | Out-Null
            $entNew++
            $propsAdded += $incomingProps.Count
            Write-Host "   [NEW]  $($entity.name)" -ForegroundColor Green

        } else {
            # Entidad existente: agregar solo las propiedades ausentes en master
            $newProps = @{}
            foreach ($key in $incomingProps.Keys) {
                if (-not $masterProps.ContainsKey($key)) {
                    $newProps[$key] = $incomingProps[$key]
                }
            }

            if ($newProps.Count -gt 0) {
                Invoke-Cypher `
                    -Statement "MATCH (e:Entity {name: `$name}) SET e += `$newProps" `
                    -Parameters @{
                        name     = $entity.name
                        newProps = $newProps
                    } | Out-Null
                $entUpd++
                $propsAdded += $newProps.Count
                Write-Host "   [UPD]  $($entity.name) (+$($newProps.Count) props: $($newProps.Keys -join ', '))" -ForegroundColor Yellow
            } else {
                $entSkip++
            }
        }
    } catch {
        Write-Host "   [FAIL] $($entity.name): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "   Entidades nuevas       : $entNew"     -ForegroundColor Green
Write-Host "   Entidades actualizadas : $entUpd"     -ForegroundColor Yellow
Write-Host "   Entidades sin cambios  : $entSkip"
Write-Host "   Propiedades agregadas  : $propsAdded" -ForegroundColor Green
Write-Host ""

# ── Merge de relaciones ───────────────────────────────────────

Write-Host "   Procesando relaciones..." -ForegroundColor Cyan
$relNew  = 0
$relSkip = 0

foreach ($conn in $data.connections) {
    try {
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
Write-Host "   Relaciones nuevas        : $relNew"  -ForegroundColor Green
Write-Host "   Relaciones ya existentes : $relSkip"
Write-Host ""

# ── Resumen ───────────────────────────────────────────────────

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   Import completado." -ForegroundColor Green
Write-Host "   Entidades  : $entNew nuevas, $entUpd actualizadas, $entSkip sin cambios"
Write-Host "   Relaciones : $relNew nuevas, $relSkip sin cambios"
Write-Host "   Propiedades agregadas: $propsAdded"
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
