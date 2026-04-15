# =============================================================
# export-obsidian.ps1 — Exporta Neo4j → Obsidian vault
# Genera un archivo .md por nodo con [[wikilinks]] y propiedades.
#
# Uso:
#   .\export-obsidian.ps1
#   .\export-obsidian.ps1 -OutputDir .\mi-vault -Neo4jPass mipass
#
# Requisito: Neo4j corriendo (brain.ps1 up)
# =============================================================

param(
    [string]$OutputDir  = ".\vault",
    [string]$Neo4jHost  = "localhost",
    [string]$Neo4jPort  = "7474",
    [string]$Neo4jUser  = "neo4j",
    [string]$Neo4jPass  = "team-brain-2025"
)

$ErrorActionPreference = "Stop"
$BaseUrl = "http://${Neo4jHost}:${Neo4jPort}/db/neo4j/tx/commit"

# ── Detectar password desde docker-compose.yml ────────────────
if ($Neo4jPass -eq "team-brain-2025" -and (Test-Path "docker-compose.yml")) {
    $authLine = Select-String -Path "docker-compose.yml" -Pattern "NEO4J_AUTH" | Select-Object -First 1
    if ($authLine) {
        $match = [regex]::Match($authLine.Line, "neo4j/(.+)")
        if ($match.Success) { $Neo4jPass = $match.Groups[1].Value.Trim() }
    }
}

# ── Helpers ───────────────────────────────────────────────────
function Invoke-Neo4j([string]$Cypher) {
    $body = @{ statements = @(@{ statement = $Cypher }) } | ConvertTo-Json -Depth 5
    $bytes = [Text.Encoding]::ASCII.GetBytes("${Neo4jUser}:${Neo4jPass}")
    $token = [Convert]::ToBase64String($bytes)
    $headers = @{ "Content-Type" = "application/json"; "Authorization" = "Basic $token" }
    return Invoke-RestMethod -Uri $BaseUrl -Method POST -Headers $headers -Body $body
}

function Safe-Name([string]$name) {
    return $name -replace '[\\/:*?"<>|]', '_'
}

# ── Banner ────────────────────────────────────────────────────
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Team Brain — Exportacion a Obsidian Vault" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# ── Verificar Neo4j ───────────────────────────────────────────
Write-Host "[1/5] Verificando conexion con Neo4j..." -ForegroundColor Gray
try {
    Invoke-Neo4j "RETURN 1" | Out-Null
    Write-Host "  [OK] Neo4j disponible en ${Neo4jHost}:${Neo4jPort}" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Neo4j no disponible. Ejecuta: .\brain.ps1 up" -ForegroundColor Red
    exit 1
}

# ── Preparar directorio vault ─────────────────────────────────
Write-Host "[2/5] Preparando directorio vault: $OutputDir" -ForegroundColor Gray
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null
Write-Host "  [OK] Directorio listo." -ForegroundColor Green

# ── Consultar nodos ───────────────────────────────────────────
Write-Host "[3/5] Consultando nodos de Neo4j..." -ForegroundColor Gray
$nodesResp = Invoke-Neo4j "MATCH (n:Entity) RETURN n ORDER BY n.entityType, n.name"
$nodeData  = $nodesResp.results[0].data
Write-Host "  [OK] $($nodeData.Count) nodos encontrados." -ForegroundColor Green

# ── Consultar relaciones ──────────────────────────────────────
Write-Host "[4/5] Consultando relaciones..." -ForegroundColor Gray
$relsResp = Invoke-Neo4j "MATCH (n:Entity)-[r]->(m:Entity) RETURN n.name, type(r), m.name ORDER BY n.name"
$relsData  = $relsResp.results[0].data

# Construir mapas de relaciones
$outgoing = @{}
$incoming = @{}
foreach ($row in $relsData) {
    $src = $row.row[0]; $rel = $row.row[1]; $dst = $row.row[2]
    if (-not $outgoing[$src]) { $outgoing[$src] = [System.Collections.Generic.List[hashtable]]::new() }
    $outgoing[$src].Add(@{ rel = $rel; node = $dst })
    if (-not $incoming[$dst]) { $incoming[$dst] = [System.Collections.Generic.List[hashtable]]::new() }
    $incoming[$dst].Add(@{ rel = $rel; node = $src })
}
Write-Host "  [OK] $($relsData.Count) relaciones indexadas." -ForegroundColor Green

# ── Generar archivos .md ──────────────────────────────────────
Write-Host "[5/5] Generando archivos Markdown..." -ForegroundColor Gray

# Propiedades a excluir del cuerpo (ya están en el encabezado)
$skipProps = @('name', 'entityType', 'updatedAt', 'createdAt')

# Agrupar nodos por tipo para el índice
$byType = @{}

foreach ($item in $nodeData) {
    $node       = $item.row[0]
    $name       = $node.name
    $entityType = $node.entityType
    $safeName   = Safe-Name $name
    $filePath   = Join-Path $OutputDir "$safeName.md"

    # Acumular para índice
    if (-not $byType[$entityType]) { $byType[$entityType] = [System.Collections.Generic.List[string]]::new() }
    $byType[$entityType].Add($name)

    # ── Construir contenido del archivo ──────────────────────
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# $name")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Tipo:** ``$entityType``")
    if ($node.updatedAt) { [void]$sb.AppendLine("**Actualizado:** $($node.updatedAt)") }
    [void]$sb.AppendLine("")

    # Propiedades del nodo
    $props = $node.PSObject.Properties | Where-Object { $_.Name -notin $skipProps -and $null -ne $_.Value -and $_.Value -ne "" }
    if ($props) {
        [void]$sb.AppendLine("## Propiedades")
        [void]$sb.AppendLine("")
        foreach ($p in $props) {
            [void]$sb.AppendLine("- **$($p.Name)**: $($p.Value)")
        }
        [void]$sb.AppendLine("")
    }

    # Relaciones salientes
    if ($outgoing[$name] -and $outgoing[$name].Count -gt 0) {
        [void]$sb.AppendLine("## Conecta con")
        [void]$sb.AppendLine("")
        foreach ($r in $outgoing[$name]) {
            [void]$sb.AppendLine("- [[$($r.node)]] ``$($r.rel)``")
        }
        [void]$sb.AppendLine("")
    }

    # Relaciones entrantes
    if ($incoming[$name] -and $incoming[$name].Count -gt 0) {
        [void]$sb.AppendLine("## Referenciado desde")
        [void]$sb.AppendLine("")
        foreach ($r in $incoming[$name]) {
            [void]$sb.AppendLine("- [[$($r.node)]] ``$($r.rel)``")
        }
        [void]$sb.AppendLine("")
    }

    $sb.ToString() | Out-File -FilePath $filePath -Encoding utf8 -NoNewline
    Write-Host "  -> $safeName.md" -ForegroundColor DarkGray
}

# ── Generar README.md (índice navegable) ─────────────────────
$readme = [System.Text.StringBuilder]::new()
[void]$readme.AppendLine("# Team Brain KLAP BYSF - Knowledge Vault")
[void]$readme.AppendLine("")
[void]$readme.AppendLine("Exportado desde Neo4j el $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$readme.AppendLine("Total de nodos: $($nodeData.Count)")
[void]$readme.AppendLine("")
[void]$readme.AppendLine("---")
[void]$readme.AppendLine("")
[void]$readme.AppendLine("## Mapa del grafo por tipo")
[void]$readme.AppendLine("")

foreach ($type in ($byType.Keys | Sort-Object)) {
    [void]$readme.AppendLine("### $type")
    [void]$readme.AppendLine("")
    foreach ($nodeName in ($byType[$type] | Sort-Object)) {
        [void]$readme.AppendLine("- [[$nodeName]]")
    }
    [void]$readme.AppendLine("")
}

$readme.ToString() | Out-File -FilePath (Join-Path $OutputDir "README.md") -Encoding utf8 -NoNewline

# ── Resumen ───────────────────────────────────────────────────
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Vault generado: $OutputDir" -ForegroundColor Green
Write-Host "  Nodos exportados : $($nodeData.Count)" -ForegroundColor Green
Write-Host "  Relaciones       : $($relsData.Count)" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Para abrir en Obsidian:" -ForegroundColor Cyan
Write-Host "    1. Abri Obsidian" -ForegroundColor White
Write-Host "    2. Archivo → Abrir vault → seleccionar la carpeta 'vault/'" -ForegroundColor White
Write-Host "    3. Abre README.md para el mapa de navegacion" -ForegroundColor White
Write-Host ""
Write-Host "  Nota: vault/ esta en .gitignore - no se sube al repositorio." -ForegroundColor Yellow
Write-Host ""
