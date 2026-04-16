# =============================================================
# install-skills.ps1 — Instala skill files en Claude Code
# Si PowerShell bloquea: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# =============================================================
param()

$SkillsSrc  = Join-Path $PSScriptRoot "skills"
$SkillsDest = Join-Path $env:USERPROFILE ".claude\skills"
$Expected   = 11
$Count      = 0

$Files = @(
    "kafka-config.md",
    "kafka-listener.md",
    "processor.md",
    "repository.md",
    "webclient.md",
    "exceptions.md",
    "testing.md",
    "openapi.md",
    "skill-registry.md",
    "sdd-microservice.md",
    "sdd-checklist.md"
)

Write-Host ""
Write-Host "Team Brain — Instalador de Skills para Claude Code" -ForegroundColor Cyan
Write-Host "Origen : $SkillsSrc"  -ForegroundColor Cyan
Write-Host "Destino: $SkillsDest" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# Verificar carpeta de origen
# -----------------------------------------------------------
if (-not (Test-Path $SkillsSrc)) {
    Write-Host "[ERROR] No se encontro la carpeta skills\ en el directorio del script." -ForegroundColor Red
    Write-Host "[ERROR] Ejecuta este script desde la raiz del proyecto team-brain."     -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Carpeta skills\ encontrada." -ForegroundColor Green

# -----------------------------------------------------------
# Crear directorio destino si no existe
# -----------------------------------------------------------
if (-not (Test-Path $SkillsDest)) {
    Write-Host "[WARN] El directorio destino no existe. Creandolo..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $SkillsDest -Force | Out-Null
        Write-Host "[OK] Directorio creado: $SkillsDest" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] No se pudo crear $SkillsDest : $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[OK] Directorio destino ya existe." -ForegroundColor Green
}

# -----------------------------------------------------------
# Copiar archivos
# -----------------------------------------------------------
Write-Host ""
Write-Host "[INFO] Copiando archivos..." -ForegroundColor Cyan

foreach ($File in $Files) {
    $Src  = Join-Path $SkillsSrc  $File
    $Dest = Join-Path $SkillsDest $File

    if (-not (Test-Path $Src)) {
        Write-Host "[WARN] Archivo no encontrado, se omite: $File" -ForegroundColor Yellow
        continue
    }

    try {
        Copy-Item -Path $Src -Destination $Dest -Force
        Write-Host "[OK] Copiado: $File" -ForegroundColor Green
        $Count++
    } catch {
        Write-Host "[ERROR] No se pudo copiar ${File}: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------
# Resumen final
# -----------------------------------------------------------
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " RESUMEN DE INSTALACION"                                        -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " Destino : $SkillsDest"
Write-Host " Copiados: $Count / $Expected archivos"
Write-Host ""

if ($Count -eq $Expected) {
    Write-Host "[OK] Todos los skills instalados correctamente." -ForegroundColor Green
} else {
    Write-Host "[WARN] Solo se copiaron $Count de $Expected archivos. Revisa los errores arriba." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[INFO] Archivos instalados en ${SkillsDest}:" -ForegroundColor Cyan
Get-ChildItem -Path $SkillsDest -Filter "*.md" | ForEach-Object {
    Write-Host "       - $($_.Name)"
}

Write-Host ""
Write-Host "[INFO] Reinicia Claude Code para que detecte los nuevos skills." -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
