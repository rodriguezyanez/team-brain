# =============================================================
# install-hooks.ps1 — Instala Guardian Angel en un proyecto
#
# Uso:
#   .\install-hooks.ps1                          <- directorio actual
#   .\install-hooks.ps1 -ProjectDir C:\ruta\app  <- proyecto indicado
#
# Para desinstalar:
#   Remove-Item "C:\ruta\app\.git\hooks\pre-commit"
#   Remove-Item "C:\ruta\app\.git\hooks\review-prompt.md"
# =============================================================

param(
    [string]$ProjectDir = (Get-Location).Path
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HooksSrc  = Join-Path $ScriptDir "hooks"
$GitHooks  = Join-Path $ProjectDir ".git\hooks"

Write-Host ""
Write-Host "=== Instalando Guardian Angel KLAP BYSF ===" -ForegroundColor Cyan
Write-Host ""

# -- Verificar repo git --
if (-not (Test-Path (Join-Path $ProjectDir ".git"))) {
    Write-Host "[ERROR] No se encontro .git en: $ProjectDir" -ForegroundColor Red
    Write-Host "        Indicá el directorio raíz del proyecto:"
    Write-Host "        .\install-hooks.ps1 -ProjectDir C:\ruta\mi-servicio"
    exit 1
}

# -- Verificar archivos fuente --
$SrcHook   = Join-Path $HooksSrc "pre-commit.sh"
$SrcPrompt = Join-Path $HooksSrc "review-prompt.md"

if (-not (Test-Path $SrcHook)) {
    Write-Host "[ERROR] hooks\pre-commit.sh no encontrado en $HooksSrc" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $SrcPrompt)) {
    Write-Host "[ERROR] hooks\review-prompt.md no encontrado en $HooksSrc" -ForegroundColor Red
    exit 1
}

# -- Crear directorio hooks si no existe --
if (-not (Test-Path $GitHooks)) { New-Item -ItemType Directory -Path $GitHooks | Out-Null }

# -- Backup si ya existe --
$DstHook = Join-Path $GitHooks "pre-commit"
if (Test-Path $DstHook) {
    Copy-Item $DstHook "$DstHook.bak" -Force
    Write-Host "[INFO] Backup creado: .git\hooks\pre-commit.bak" -ForegroundColor Yellow
}

# -- Copiar hook y prompt --
Copy-Item $SrcHook   $DstHook                                    -Force
Copy-Item $SrcPrompt (Join-Path $GitHooks "review-prompt.md")   -Force

Write-Host "[OK] Hook instalado en: $DstHook" -ForegroundColor Green
Write-Host "[OK] Prompt copiado en: $GitHooks\review-prompt.md" -ForegroundColor Green
Write-Host ""
Write-Host "=== Guardian Angel activo en: $ProjectDir ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Cada commit en archivos .java/.kt sera revisado."
Write-Host "  Commit urgente sin revision: git commit --no-verify"
Write-Host "  Desinstalar: Remove-Item `"$DstHook`""
Write-Host ""
