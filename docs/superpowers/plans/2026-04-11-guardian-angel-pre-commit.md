# Guardian Angel — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar un hook git pre-commit que revisa cada cambio contra las reglas DO/DON'T del equipo KLAP BYSF usando Claude CLI en modo no-interactivo, bloqueando el commit si hay violaciones.

**Architecture:** El hook `pre-commit` es un bash script instalado en `.git/hooks/` del proyecto destino. Al ejecutarse, obtiene el diff staged de archivos Java, construye un prompt con `hooks/review-prompt.md` + el diff, llama a `claude --print` y parsea la línea `GUARDIAN_ANGEL_RESULT=PASS/FAIL`. Si falla, bloquea el commit con salida 1. El desarrollador puede saltear con `git commit --no-verify`. Los scripts de instalación copian el hook y el prompt al proyecto destino.

**Tech Stack:** bash, batch/CMD, PowerShell, Claude Code CLI (`claude --print`), git

---

## Archivos a crear / modificar

| Acción | Archivo | Responsabilidad |
|--------|---------|-----------------|
| Crear | `hooks/review-prompt.md` | Prompt con las 10 reglas DO/DON'T que Claude evalúa |
| Crear | `hooks/pre-commit.sh` | Hook bash — obtiene diff, llama Claude, parsea resultado |
| Crear | `hooks/pre-commit.bat` | Equivalente Windows CMD para ejecución manual |
| Crear | `hooks/pre-commit.ps1` | Equivalente PowerShell para ejecución manual |
| Crear | `install-hooks.sh` | Copia el hook y el prompt a `.git/hooks/` del proyecto destino |
| Crear | `install-hooks.bat` | Equivalente Windows CMD |
| Crear | `install-hooks.ps1` | Equivalente PowerShell |
| Modificar | `ONBOARDING.md` | Agregar sección Guardian Angel con instrucciones de instalación y bypass |
| Modificar | `setup.bat` | Agregar PASO 8 opcional: instalar Guardian Angel |
| Modificar | `setup.ps1` | Ídem PowerShell |
| Modificar | `setup.sh` | Ídem bash |
| Modificar | `ENRICHMENT-PLAN.md` | Marcar Fase 5 como completada |

---

## Task 1: Crear `hooks/review-prompt.md`

**Files:**
- Create: `hooks/review-prompt.md`

- [ ] **Step 1: Crear el archivo con las 10 reglas**

```markdown
# Guardian Angel — Revisión de código KLAP BYSF

Eres el Guardian Angel del equipo KLAP BYSF. Revisa el diff de git que aparece al final
y verificá cada regla del estándar del equipo.

## Instrucciones

Para cada regla:
- Responde ✅ si el diff cumple la regla, o si el diff no incluye código relevante para esa regla.
- Responde ❌ si el diff VIOLA la regla. Indicá el archivo y la línea afectada.

Sé directo y específico. No expliques la regla, solo reportá violaciones concretas.

## Reglas a verificar

### R1 — JavaDoc obligatorio
✅/❌: Todos los métodos públicos nuevos o modificados tienen JavaDoc (`/** ... */`).
Excepción: métodos `toString()`, `equals()`, `hashCode()`, `main()` no requieren JavaDoc.

### R2 — Sin JPA/Hibernate
✅/❌: El diff no introduce `@Entity`, `@Table`, `@Column`, `EntityManager`,
`JpaRepository`, `CrudRepository`, ni imports de `javax.persistence` o `jakarta.persistence`.

### R3 — SQL en ConstantsQuery
✅/❌: No hay strings SQL hardcodeados en el código. Todo SQL debe estar en
`ConstantsQuery.java` y referenciado como `ConstantsQuery.XXX`.
Considera SQL cualquier string que contenga: SELECT, INSERT, UPDATE, DELETE, FROM, WHERE.

### R4 — enable.metrics.push=false
✅/❌: Si el diff modifica o crea configuración Kafka (`*KafkaConfig*`),
incluye `enable.metrics.push=false`. Esta propiedad es crítica para evitar OOM en MSK.

### R5 — max.poll.records=1
✅/❌: Si el diff crea o modifica un consumer Kafka (`*KafkaConfig*`),
incluye `max.poll.records=1`.

### R6 — Naming conventions
✅/❌: Las clases siguen el naming del equipo:
- Interfaces: `XxxService`, `XxxProcessor`, `XxxRepository` (sin sufijo Impl)
- Implementaciones: `XxxServiceImpl`, `XxxProcessorImpl` anotadas con `@Service`
- Listeners: `XxxKafkaListener` con `@Component`
- DTOs: `XxxInputDto`, `XxxOutputDto`, `XxxRequestDto`, `XxxResponseDto`
- Excepciones: `XxxException`, `XxxClientException`, `XxxPersistenceException`
- Configs: `XxxKafkaConfig`, `XxxClientConfig` con `@Configuration`

### R7 — Sin OFFSET/LIMIT en paginación de tablas grandes
✅/❌: Si el diff incluye queries SQL de paginación, usa cursor-based
(`WHERE id > :lastId ORDER BY id LIMIT :pageSize`) en lugar de `OFFSET :n LIMIT :m`.

### R8 — AckMode MANUAL en Kafka
✅/❌: Si el diff crea o modifica un `KafkaListenerContainerFactory`,
el `AckMode` es `MANUAL` (no `BATCH`, no `AUTO`, no `RECORD`).

### R9 — Sin bypass del service layer
✅/❌: Controllers y listeners no inyectan ni llaman directamente a repositorios.
Siempre interactúan con la interfaz de servicio (`XxxService`, `XxxProcessor`).

### R10 — ErrorHandlingDeserializer
✅/❌: Si el diff crea o modifica la configuración de un consumer Kafka,
usa `ErrorHandlingDeserializer` como wrapper del `JsonDeserializer`.

## Formato de respuesta OBLIGATORIO

Respondé EXACTAMENTE con este formato. No agregues texto antes ni después:

```
R1 — JavaDoc obligatorio: ✅
R2 — Sin JPA/Hibernate: ✅
R3 — SQL en ConstantsQuery: ❌ LiquidacionRepository.java:45 — SQL hardcodeado: "SELECT * FROM liquidaciones WHERE..."
R4 — enable.metrics.push=false: ✅
R5 — max.poll.records=1: ✅
R6 — Naming conventions: ✅
R7 — Sin OFFSET/LIMIT: ✅
R8 — AckMode MANUAL: ✅
R9 — Sin bypass service layer: ✅
R10 — ErrorHandlingDeserializer: ✅

GUARDIAN_ANGEL_RESULT=FAIL
```

Si todo está OK, la última línea es `GUARDIAN_ANGEL_RESULT=PASS`.
Si hay una o más violaciones (❌), la última línea es `GUARDIAN_ANGEL_RESULT=FAIL`.
NO incluyas texto adicional después de `GUARDIAN_ANGEL_RESULT`.
```

- [ ] **Step 2: Verificar que el archivo existe**

```bash
cat hooks/review-prompt.md | head -5
# Esperado: # Guardian Angel — Revisión de código KLAP BYSF
```

- [ ] **Step 3: Commit**

```bash
git add hooks/review-prompt.md
git commit -m "feat: add GGA review-prompt with 10 KLAP BYSF rules"
```

---

## Task 2: Crear `hooks/pre-commit.sh`

**Files:**
- Create: `hooks/pre-commit.sh`

- [ ] **Step 1: Crear el script bash**

```bash
#!/bin/bash
# =============================================================
# Guardian Angel — Hook pre-commit KLAP BYSF
# Revisa el diff staged contra las reglas del equipo via Claude.
#
# Instalación: install-hooks.sh /ruta/al/proyecto
# Bypass urgente: git commit --no-verify
# =============================================================

# ── Obtener diff staged de archivos Java ─────────────────────
DIFF=$(git diff --cached --diff-filter=ACMR -- "*.java" "*.kt" "*.groovy" 2>/dev/null)

if [ -z "$DIFF" ]; then
  # Sin cambios en código Java/Kotlin → permitir commit sin revisión
  exit 0
fi

# ── Localizar review-prompt.md ────────────────────────────────
# El hook está en .git/hooks/pre-commit y review-prompt.md se copia junto a él
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
REVIEW_PROMPT="$HOOK_DIR/review-prompt.md"

if [ ! -f "$REVIEW_PROMPT" ]; then
  echo "[GGA] WARN: review-prompt.md no encontrado en $HOOK_DIR"
  echo "[GGA] Salteando revisión. Para reinstalar: install-hooks.sh"
  exit 0
fi

# ── Verificar Claude CLI ──────────────────────────────────────
if ! command -v claude &> /dev/null; then
  echo "[GGA] WARN: Claude CLI no encontrado. Salteando revisión."
  echo "     Instala con: npm install -g @anthropic-ai/claude-code"
  exit 0
fi

# ── Construir prompt completo ─────────────────────────────────
PROMPT_CONTENT=$(cat "$REVIEW_PROMPT")
FULL_PROMPT="${PROMPT_CONTENT}

## Diff a revisar

\`\`\`diff
${DIFF}
\`\`\`"

# ── Llamar a Claude en modo no-interactivo ───────────────────
echo ""
echo "🔍 Guardian Angel revisando el commit..."

RESULT=$(echo "$FULL_PROMPT" | claude --print 2>&1) || true

# ── Parsear resultado ─────────────────────────────────────────
if echo "$RESULT" | grep -q "GUARDIAN_ANGEL_RESULT=FAIL"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚫  Guardian Angel bloqueó el commit — violaciones encontradas"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "$RESULT" | grep -v "^GUARDIAN_ANGEL_RESULT"
  echo ""
  echo "Corregí las violaciones y volvé a hacer commit."
  echo "Commit urgente sin revisión: git commit --no-verify"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi

if echo "$RESULT" | grep -q "GUARDIAN_ANGEL_RESULT=PASS"; then
  echo ""
  echo "✅ Guardian Angel: commit aprobado"
  echo ""
  echo "$RESULT" | grep -v "^GUARDIAN_ANGEL_RESULT"
  exit 0
fi

# Claude no devolvió resultado reconocible → fail-open (no bloquear)
echo ""
echo "[GGA] WARN: Revisión sin resultado reconocible. Permitiendo commit (fail-open)."
echo "$RESULT"
exit 0
```

- [ ] **Step 2: Dar permisos de ejecución**

```bash
chmod +x hooks/pre-commit.sh
```

- [ ] **Step 3: Verificar que el shebang y la lógica básica son correctos**

```bash
bash -n hooks/pre-commit.sh && echo "Sintaxis OK"
# Esperado: Sintaxis OK
```

- [ ] **Step 4: Commit**

```bash
git add hooks/pre-commit.sh
git commit -m "feat: add GGA pre-commit bash hook"
```

---

## Task 3: Crear `hooks/pre-commit.bat` y `hooks/pre-commit.ps1`

**Files:**
- Create: `hooks/pre-commit.bat`
- Create: `hooks/pre-commit.ps1`

> Nota: el hook instalado en `.git/hooks/pre-commit` siempre es el `.sh` (Git Bash lo ejecuta en Windows también). Los archivos `.bat` y `.ps1` son para ejecución manual o testing desde CMD/PowerShell.

- [ ] **Step 1: Crear `hooks/pre-commit.bat`**

```batch
@echo off
REM =============================================================
REM Guardian Angel — Hook pre-commit KLAP BYSF (Windows CMD)
REM Para ejecucion manual. El hook real (.git/hooks/pre-commit)
REM usa pre-commit.sh via Git Bash.
REM Bypass urgente: git commit --no-verify
REM =============================================================
setlocal EnableDelayedExpansion

echo.
echo [GGA] Guardian Angel revisando el commit...
echo.

REM -- Verificar claude CLI --
where claude >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [GGA] WARN: Claude CLI no encontrado. Salteando revision.
    echo       Instala con: npm install -g @anthropic-ai/claude-code
    exit /b 0
)

REM -- Verificar review-prompt.md --
set SCRIPT_DIR=%~dp0
if not exist "%SCRIPT_DIR%review-prompt.md" (
    echo [GGA] WARN: review-prompt.md no encontrado en %SCRIPT_DIR%
    echo       Salteando revision.
    exit /b 0
)

REM -- Obtener diff staged --
git diff --cached --diff-filter=ACMR -- "*.java" "*.kt" > "%TEMP%\gga_diff.txt" 2>nul
for %%A in ("%TEMP%\gga_diff.txt") do if %%~zA equ 0 (
    echo [GGA] Sin cambios Java/Kotlin staged. Commit permitido.
    del "%TEMP%\gga_diff.txt" >nul 2>&1
    exit /b 0
)

REM -- Construir prompt --
copy /y "%SCRIPT_DIR%review-prompt.md" "%TEMP%\gga_prompt.txt" >nul
echo. >> "%TEMP%\gga_prompt.txt"
echo ## Diff a revisar >> "%TEMP%\gga_prompt.txt"
echo ```diff >> "%TEMP%\gga_prompt.txt"
type "%TEMP%\gga_diff.txt" >> "%TEMP%\gga_prompt.txt"
echo ``` >> "%TEMP%\gga_prompt.txt"

REM -- Llamar a Claude --
claude --print < "%TEMP%\gga_prompt.txt" > "%TEMP%\gga_result.txt" 2>&1

REM -- Parsear resultado --
findstr /C:"GUARDIAN_ANGEL_RESULT=FAIL" "%TEMP%\gga_result.txt" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo  GGA Guardian Angel bloqueo el commit - violaciones encontradas
    echo ============================================================
    type "%TEMP%\gga_result.txt"
    echo.
    echo Corregi las violaciones y volvé a hacer commit.
    echo Commit urgente sin revision: git commit --no-verify
    del "%TEMP%\gga_diff.txt" "%TEMP%\gga_prompt.txt" "%TEMP%\gga_result.txt" >nul 2>&1
    exit /b 1
)

echo.
echo [GGA] Commit aprobado.
type "%TEMP%\gga_result.txt"
del "%TEMP%\gga_diff.txt" "%TEMP%\gga_prompt.txt" "%TEMP%\gga_result.txt" >nul 2>&1
exit /b 0
```

- [ ] **Step 2: Crear `hooks/pre-commit.ps1`**

```powershell
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
Write-Host "🔍 Guardian Angel revisando el commit..." -ForegroundColor Cyan

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
    Write-Host "🚫  Guardian Angel bloqueó el commit" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    $Result -split "`n" | Where-Object { $_ -notmatch "^GUARDIAN_ANGEL_RESULT" } | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Corregí las violaciones y volvé a hacer commit." -ForegroundColor Yellow
    Write-Host "Commit urgente sin revisión: git commit --no-verify" -ForegroundColor Yellow
    Remove-Item $TmpDiff, $TmpPrompt, $TmpResult -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
Write-Host "✅ Guardian Angel: commit aprobado" -ForegroundColor Green
$Result -split "`n" | Where-Object { $_ -notmatch "^GUARDIAN_ANGEL_RESULT" } | ForEach-Object { Write-Host $_ }
Remove-Item $TmpDiff, $TmpPrompt, $TmpResult -ErrorAction SilentlyContinue
exit 0
```

- [ ] **Step 3: Verificar sintaxis del .sh (el principal)**

```bash
bash -n hooks/pre-commit.sh && echo "OK"
# Esperado: OK
```

- [ ] **Step 4: Commit**

```bash
git add hooks/pre-commit.bat hooks/pre-commit.ps1
git commit -m "feat: add GGA pre-commit Windows wrappers (bat + ps1)"
```

---

## Task 4: Crear `install-hooks.sh`

**Files:**
- Create: `install-hooks.sh`

- [ ] **Step 1: Crear el script**

```bash
#!/bin/bash
# =============================================================
# install-hooks.sh — Instala Guardian Angel en un proyecto
#
# Uso:
#   ./install-hooks.sh                    <- instala en el directorio actual
#   ./install-hooks.sh /ruta/al/proyecto  <- instala en el proyecto indicado
#
# Para desinstalar:
#   rm /ruta/al/proyecto/.git/hooks/pre-commit
#   rm /ruta/al/proyecto/.git/hooks/review-prompt.md
# =============================================================

set -e

TEAM_BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_SRC="$TEAM_BRAIN_DIR/hooks"
PROJECT_DIR="${1:-$(pwd)}"
GIT_HOOKS="$PROJECT_DIR/.git/hooks"

echo ""
echo "=== Instalando Guardian Angel KLAP BYSF ==="
echo ""

# -- Verificar que es un repo git --
if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "[ERROR] No se encontró .git en: $PROJECT_DIR"
  echo "        Indicá el directorio raíz de tu proyecto:"
  echo "        ./install-hooks.sh ~/proyectos/mi-servicio"
  exit 1
fi

# -- Verificar que existen los archivos fuente --
if [ ! -f "$HOOKS_SRC/pre-commit.sh" ]; then
  echo "[ERROR] hooks/pre-commit.sh no encontrado en $HOOKS_SRC"
  exit 1
fi
if [ ! -f "$HOOKS_SRC/review-prompt.md" ]; then
  echo "[ERROR] hooks/review-prompt.md no encontrado en $HOOKS_SRC"
  exit 1
fi

# -- Backup del hook existente --
if [ -f "$GIT_HOOKS/pre-commit" ]; then
  cp "$GIT_HOOKS/pre-commit" "$GIT_HOOKS/pre-commit.bak"
  echo "[INFO] Backup creado: .git/hooks/pre-commit.bak"
fi

# -- Copiar hook y prompt --
cp "$HOOKS_SRC/pre-commit.sh"    "$GIT_HOOKS/pre-commit"
cp "$HOOKS_SRC/review-prompt.md" "$GIT_HOOKS/review-prompt.md"
chmod +x "$GIT_HOOKS/pre-commit"

echo "[OK] Hook instalado en: $GIT_HOOKS/pre-commit"
echo "[OK] Prompt copiado en: $GIT_HOOKS/review-prompt.md"
echo ""
echo "=== Guardian Angel activo en: $PROJECT_DIR ==="
echo ""
echo "  Cada commit en archivos .java/.kt será revisado."
echo "  Commit urgente sin revisión: git commit --no-verify"
echo "  Desinstalar: rm $GIT_HOOKS/pre-commit"
echo ""
```

- [ ] **Step 2: Dar permisos de ejecución**

```bash
chmod +x install-hooks.sh
```

- [ ] **Step 3: Verificar sintaxis**

```bash
bash -n install-hooks.sh && echo "Sintaxis OK"
# Esperado: Sintaxis OK
```

- [ ] **Step 4: Commit**

```bash
git add install-hooks.sh
git commit -m "feat: add install-hooks.sh for Linux/macOS"
```

---

## Task 5: Crear `install-hooks.bat` e `install-hooks.ps1`

**Files:**
- Create: `install-hooks.bat`
- Create: `install-hooks.ps1`

- [ ] **Step 1: Crear `install-hooks.bat`**

```batch
@echo off
REM =============================================================
REM install-hooks.bat — Instala Guardian Angel en un proyecto
REM
REM Uso:
REM   install-hooks.bat                       <- instala en directorio actual
REM   install-hooks.bat C:\ruta\al\proyecto   <- instala en proyecto indicado
REM
REM Para desinstalar:
REM   del C:\ruta\proyecto\.git\hooks\pre-commit
REM   del C:\ruta\proyecto\.git\hooks\review-prompt.md
REM =============================================================
setlocal EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
set HOOKS_SRC=%SCRIPT_DIR%hooks

REM -- Determinar proyecto destino --
if "%~1"=="" (
    set PROJECT_DIR=%CD%
) else (
    set PROJECT_DIR=%~1
)

echo.
echo === Instalando Guardian Angel KLAP BYSF ===
echo.

REM -- Verificar repo git --
if not exist "%PROJECT_DIR%\.git" (
    echo [ERROR] No se encontro .git en: %PROJECT_DIR%
    echo         Indica el directorio raiz del proyecto:
    echo         install-hooks.bat C:\ruta\mi-servicio
    exit /b 1
)

set GIT_HOOKS=%PROJECT_DIR%\.git\hooks

REM -- Verificar archivos fuente --
if not exist "%HOOKS_SRC%\pre-commit.sh" (
    echo [ERROR] hooks\pre-commit.sh no encontrado en %HOOKS_SRC%
    exit /b 1
)
if not exist "%HOOKS_SRC%\review-prompt.md" (
    echo [ERROR] hooks\review-prompt.md no encontrado en %HOOKS_SRC%
    exit /b 1
)

REM -- Crear directorio hooks si no existe --
if not exist "%GIT_HOOKS%" mkdir "%GIT_HOOKS%"

REM -- Backup si ya existe pre-commit --
if exist "%GIT_HOOKS%\pre-commit" (
    copy /y "%GIT_HOOKS%\pre-commit" "%GIT_HOOKS%\pre-commit.bak" >nul
    echo [INFO] Backup creado: .git\hooks\pre-commit.bak
)

REM -- Copiar hook y prompt --
copy /y "%HOOKS_SRC%\pre-commit.sh"    "%GIT_HOOKS%\pre-commit"    >nul
copy /y "%HOOKS_SRC%\review-prompt.md" "%GIT_HOOKS%\review-prompt.md" >nul

echo [OK] Hook instalado en: %GIT_HOOKS%\pre-commit
echo [OK] Prompt copiado en: %GIT_HOOKS%\review-prompt.md
echo.
echo === Guardian Angel activo en: %PROJECT_DIR% ===
echo.
echo   Cada commit en archivos .java/.kt sera revisado.
echo   Commit urgente sin revision: git commit --no-verify
echo   Desinstalar: del "%GIT_HOOKS%\pre-commit"
echo.

endlocal
exit /b 0
```

- [ ] **Step 2: Crear `install-hooks.ps1`**

```powershell
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
    Write-Host "[ERROR] No se encontró .git en: $ProjectDir" -ForegroundColor Red
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
Write-Host "  Cada commit en archivos .java/.kt será revisado."
Write-Host "  Commit urgente sin revisión: git commit --no-verify"
Write-Host "  Desinstalar: Remove-Item `"$DstHook`""
Write-Host ""
```

- [ ] **Step 3: Commit**

```bash
git add install-hooks.bat install-hooks.ps1
git commit -m "feat: add install-hooks.bat and install-hooks.ps1 for Windows"
```

---

## Task 6: Actualizar `ONBOARDING.md`

**Files:**
- Modify: `ONBOARDING.md`

- [ ] **Step 1: Agregar sección Guardian Angel al final del ONBOARDING.md**

Buscar la sección final del archivo y agregar antes del cierre:

```markdown
---

## Guardian Angel — Code review automático pre-commit

El equipo tiene un hook pre-commit que usa Claude para revisar cada commit contra
las reglas DO/DON'T del estándar KLAP BYSF antes de permitirlo.

### Qué revisa

| Regla | Descripción |
|-------|-------------|
| R1 | JavaDoc en todos los métodos públicos |
| R2 | Sin JPA/Hibernate (solo JdbcTemplate) |
| R3 | SQL únicamente en `ConstantsQuery.java` |
| R4 | `enable.metrics.push=false` en KafkaConfig |
| R5 | `max.poll.records=1` en consumers |
| R6 | Naming conventions del equipo |
| R7 | Paginación cursor-based (sin OFFSET/LIMIT) |
| R8 | `AckMode.MANUAL` en containers Kafka |
| R9 | Sin bypass del service layer |
| R10 | `ErrorHandlingDeserializer` en consumers |

### Instalación en tu proyecto

```bash
# Linux / macOS / Git Bash
./install-hooks.sh /ruta/a/tu/proyecto

# Windows CMD
install-hooks.bat C:\ruta\a\tu\proyecto

# Windows PowerShell
.\install-hooks.ps1 -ProjectDir C:\ruta\a\tu\proyecto
```

### Cómo funciona

1. Hacés `git commit`
2. El hook obtiene el diff staged de archivos `.java` / `.kt`
3. Claude revisa el diff contra las 10 reglas
4. Si todo OK → `✅ Guardian Angel: commit aprobado` → commit procede
5. Si hay violaciones → `🚫 Guardian Angel bloqueó el commit` + detalle → commit cancelado

### Bypass para commits urgentes

```bash
git commit --no-verify -m "hotfix: corrección urgente en producción"
```

> Usar solo en emergencias reales. El hook existe para proteger la calidad del código.

### Desinstalar

```bash
rm .git/hooks/pre-commit
rm .git/hooks/review-prompt.md
```
```

- [ ] **Step 2: Verificar que la sección existe**

```bash
grep -n "Guardian Angel" ONBOARDING.md
# Esperado: línea con "Guardian Angel"
```

- [ ] **Step 3: Commit**

```bash
git add ONBOARDING.md
git commit -m "docs: add Guardian Angel section to ONBOARDING.md"
```

---

## Task 7: Actualizar `setup.bat`, `setup.ps1` y `setup.sh`

**Files:**
- Modify: `setup.bat`
- Modify: `setup.ps1`
- Modify: `setup.sh`

> Agregar PASO 8 opcional al final de cada setup, antes del resumen final. El paso es opcional: si el dev no especifica un proyecto destino, se saltea con un aviso.

- [ ] **Step 1: Agregar en `setup.bat` antes de `:END_SUCCESS`**

Buscar el bloque `REM RESUMEN FINAL` en `setup.bat` e insertar antes de él:

```batch
REM =============================================================
REM PASO 8: Instalar Guardian Angel (opcional)
REM =============================================================
echo ── PASO 8: Guardian Angel hook pre-commit (opcional) ──────
echo.
echo   Para instalar el hook en tu proyecto:
echo     install-hooks.bat C:\ruta\a\tu\proyecto
echo.
echo   El hook revisara cada commit Java contra las reglas del equipo.
echo.
```

- [ ] **Step 2: Agregar en `setup.ps1` el equivalente PowerShell**

Buscar el bloque de resumen final en `setup.ps1` e insertar antes:

```powershell
# PASO 8: Guardian Angel (opcional)
Write-Host "── PASO 8: Guardian Angel hook pre-commit (opcional) ──────" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Para instalar el hook en tu proyecto:" -ForegroundColor White
Write-Host "    .\install-hooks.ps1 -ProjectDir C:\ruta\tu\proyecto" -ForegroundColor Yellow
Write-Host ""
Write-Host "  El hook revisará cada commit Java contra las reglas del equipo." -ForegroundColor White
Write-Host ""
```

- [ ] **Step 3: Agregar en `setup.sh` el equivalente bash**

Buscar el bloque de resumen final en `setup.sh` e insertar antes:

```bash
# PASO 8: Guardian Angel (opcional)
echo "── PASO 8: Guardian Angel hook pre-commit (opcional) ──────"
echo ""
echo "  Para instalar el hook en tu proyecto:"
echo "    ./install-hooks.sh /ruta/a/tu/proyecto"
echo ""
echo "  El hook revisará cada commit Java contra las reglas del equipo."
echo ""
```

- [ ] **Step 4: Commit**

```bash
git add setup.bat setup.ps1 setup.sh
git commit -m "feat: add optional Guardian Angel step to setup scripts"
```

---

## Task 8: Marcar Fase 5 como completada en `ENRICHMENT-PLAN.md`

**Files:**
- Modify: `ENRICHMENT-PLAN.md`

- [ ] **Step 1: Actualizar estado de la Fase 5**

Cambiar:
```
**Prioridad**: Media | **Esfuerzo**: Medio | **Estado**: `[ ] Pendiente`
```
Por:
```
**Prioridad**: Media | **Esfuerzo**: Medio | **Estado**: `[x] Completada`
```

- [ ] **Step 2: Marcar todas las tareas de la Fase 5 como completadas**

Cambiar todos los `- [ ]` de la Fase 5 por `- [x]`.

- [ ] **Step 3: Actualizar tabla resumen y contador**

```markdown
| 5 | Guardian Angel — code review pre-commit | Media | `[x] Completada` |
```

Contador: `**Completadas: 6 / 7**`
Header: `**Estado general: 6 / 7 fases completadas**`

- [ ] **Step 4: Commit final**

```bash
git add ENRICHMENT-PLAN.md
git commit -m "chore: mark Phase 5 Guardian Angel as completed"
```

---

## Self-Review

### Cobertura del spec (Fase 5 de ENRICHMENT-PLAN.md)

| Tarea del plan | Task en este doc |
|----------------|-----------------|
| `hooks/pre-commit.sh` | Task 2 ✅ |
| `hooks/pre-commit.bat` | Task 3 ✅ |
| `hooks/pre-commit.ps1` | Task 3 ✅ |
| `install-hooks.sh` | Task 4 ✅ |
| `install-hooks.bat` | Task 5 ✅ |
| `install-hooks.ps1` | Task 5 ✅ |
| `hooks/review-prompt.md` | Task 1 ✅ |
| Modo `--bypass` (`git commit --no-verify`) | Task 2 + Task 6 ✅ |
| Documentar en `ONBOARDING.md` | Task 6 ✅ |
| `install-hooks` como paso opcional en `setup.bat` | Task 7 ✅ |

### Posibles riesgos

- `claude --print` puede no estar disponible en todas las versiones de Claude Code. El hook falla-abierto (exit 0) si Claude no responde de forma reconocible — el commit se permite.
- En Windows, git usa Git Bash para ejecutar hooks, por eso el hook instalado siempre es el `.sh`. Los `.bat`/`.ps1` son solo para ejecución manual.
- La detección de SQL hardcodeado por strings (SELECT, FROM, etc.) puede generar falsos positivos en comentarios. Regla R3 aplica solo a strings Java, no comentarios — Claude debería manejarlo correctamente.
