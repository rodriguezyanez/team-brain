# =============================================================
# backup.ps1 — Backup y restore de los volumenes de Neo4j
#
# Uso:
#   .\backup.ps1                          -> crear backup
#   .\backup.ps1 -Action restore -File "backups\neo4j-backup-XXX.tar.gz"
#   .\backup.ps1 -Action list             -> listar backups
#
# Si PowerShell bloquea la ejecucion, corre primero:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# =============================================================

param(
    [ValidateSet("backup","restore","list")]
    [string]$Action = "backup",
    [string]$File   = ""
)

$BackupDir = "backups"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# ── BACKUP ────────────────────────────────────────────────────
if ($Action -eq "backup") {
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

    $BackupFile = "$BackupDir\neo4j-backup-$Timestamp.tar.gz"
    Write-Host ""
    Write-Host "Creando backup..."
    Write-Host "  Archivo: $BackupFile"

    $AbsBackupDir = (Resolve-Path $BackupDir).Path

    docker run --rm `
        -v team-brain_neo4j_data:/data `
        -v "${AbsBackupDir}:/backup" `
        alpine `
        tar czf /backup/neo4j-backup-$Timestamp.tar.gz /data

    if ($LASTEXITCODE -eq 0) {
        $size = (Get-Item $BackupFile).Length / 1MB
        Write-Host ("  [OK] Backup creado ({0:N1} MB)" -f $size) -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Fallo el backup. Verifica que Docker este corriendo." -ForegroundColor Red
        exit 1
    }
}

# ── RESTORE ───────────────────────────────────────────────────
elseif ($Action -eq "restore") {
    if ($File -eq "") {
        Write-Host "[ERROR] Especifica el archivo con -File" -ForegroundColor Red
        Write-Host "        Ejemplo: .\backup.ps1 -Action restore -File 'backups\neo4j-backup-20250410_120000.tar.gz'"
        exit 1
    }

    if (-not (Test-Path $File)) {
        Write-Host "[ERROR] Archivo no encontrado: $File" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "ADVERTENCIA: esto sobreescribira los datos actuales de Neo4j." -ForegroundColor Yellow
    $confirm = Read-Host "¿Continuar? (s/N)"
    if ($confirm -notmatch "^[sS]$") {
        Write-Host "Cancelado."
        exit 0
    }

    Write-Host ""
    Write-Host "Deteniendo Neo4j..."
    docker compose down

    Write-Host "Restaurando desde $File..."
    $AbsCwd  = (Get-Location).Path
    $RelFile = $File -replace "\\", "/"

    docker run --rm `
        -v team-brain_neo4j_data:/data `
        -v "${AbsCwd}:/backup" `
        alpine `
        sh -c "rm -rf /data/* && tar xzf /backup/$RelFile -C / --strip-components=0"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Reiniciando Neo4j..."
        docker compose up -d
        Write-Host "[OK] Restauracion completa." -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Fallo la restauracion." -ForegroundColor Red
        Write-Host "        Levanta Neo4j manualmente con: docker compose up -d"
        exit 1
    }
}

# ── LIST ──────────────────────────────────────────────────────
elseif ($Action -eq "list") {
    Write-Host ""
    Write-Host "Backups disponibles en $BackupDir\:"
    Write-Host ""

    if (-not (Test-Path $BackupDir)) {
        Write-Host "  (ninguno)"
    } else {
        $files = Get-ChildItem "$BackupDir\neo4j-backup-*.tar.gz" -ErrorAction SilentlyContinue
        if ($files.Count -eq 0) {
            Write-Host "  (ninguno)"
        } else {
            $files | ForEach-Object {
                $sizeMB = "{0:N1} MB" -f ($_.Length / 1MB)
                Write-Host ("  {0,-50} {1}" -f $_.Name, $sizeMB)
            }
        }
    }
    Write-Host ""
}
