# =============================================================
# Guardian Angel — Hook pre-commit KLAP BYSF (PowerShell)
# Para ejecucion manual. El hook real usa pre-commit.sh via Git Bash.
# Bypass urgente: git commit --no-verify
# =============================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TmpDiff   = Join-Path $env:TEMP "gga_diff.txt"
$TmpPrompt = Join-Path $env:TEMP "gga_prompt.txt"
$TmpResult = Join-Path $env:TEMP "gga_result.txt"

Write-Host ""
Write-Host "Revisando el commit con Guardian Angel..." -ForegroundColor Cyan

# -- Verificar claude CLI --
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "[GGA] WARN: Claude CLI no encontrado. Salteando revision." -ForegroundColor Yellow
    Write-Host "      Instala con: npm install -g @anthropic-ai/claude-code"
    exit 0
}

# -- Verificar review-prompt.md --
$ReviewPrompt = Join-Path $ScriptDir "review-prompt.md"
if (-not (Test-Path $ReviewPrompt)) {
    Write-Host "[GGA] WARN: review-prompt.md no encontrado. Salteando revision." -ForegroundColor Yellow
    exit 0
}

# -- Obtener diff staged --
$Diff = git diff --cached --diff-filter=ACMR -- "*.java" "*.kt" 2>$null
if ([string]::IsNullOrWhiteSpace($Diff)) {
    Write-Host "[GGA] Sin cambios Java/Kotlin staged. Commit permitido." -ForegroundColor Green
    exit 0
}

# -- Construir prompt --
$PromptContent = Get-Content $ReviewPrompt -Raw
$FullPrompt = "$PromptContent`n`n## Diff a revisar`n``````diff`n$Diff`n``````"
$FullPrompt | Out-File -FilePath $TmpPrompt -Encoding utf8

# -- Llamar a Claude --
Get-Content $TmpPrompt | claude --print 2>&1 | Out-File -FilePath $TmpResult -Encoding utf8

# -- Parsear resultado --
$Result = Get-Content $TmpResult -Raw

if ($Result -match "GUARDIAN_ANGEL_RESULT=FAIL") {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "  Guardian Angel bloqueo el commit" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    $Result -split "`n" | Where-Object { $_ -notmatch "^GUARDIAN_ANGEL_RESULT" } | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Corregi las violaciones y volve a hacer commit." -ForegroundColor Yellow
    Write-Host "Commit urgente sin revision: git commit --no-verify" -ForegroundColor Yellow
    Remove-Item $TmpDiff, $TmpPrompt, $TmpResult -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
Write-Host "[GGA] Commit aprobado." -ForegroundColor Green
$Result -split "`n" | Where-Object { $_ -notmatch "^GUARDIAN_ANGEL_RESULT" } | ForEach-Object { Write-Host $_ }
Remove-Item $TmpDiff, $TmpPrompt, $TmpResult -ErrorAction SilentlyContinue
exit 0
