# Local Memory Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cuando Neo4j no está disponible, las memorias se guardan localmente en `~/.claude/pending-memories.jsonl` y se sincronizan con Neo4j al reconectar con `brain.bat sync`.

**Architecture:** Claude detecta el fallo del MCP `team-brain` y escribe la memoria en un archivo JSONL local. Un script de sync lee ese archivo, empuja cada entrada a Neo4j vía HTTP API (puerto 7474) y limpia las entradas procesadas. CLAUDE.md incluye el protocolo de fallback y chequeo al inicio de sesión.

**Tech Stack:** PowerShell, Bash, CMD, Neo4j HTTP API (Cypher over HTTP), JSONL

---

## Archivos involucrados

| Acción | Archivo |
|--------|---------|
| Crear | `brain-sync.ps1` |
| Crear | `brain-sync.bat` |
| Crear | `brain-sync.sh` |
| Modificar | `brain.bat` — agregar comando `sync` |
| Modificar | `brain.ps1` — agregar comando `sync` |
| Modificar | `CLAUDE.md` — agregar protocolo de fallback local |
| Modificar | `GUIA-PRACTICA.md` — documentar el comando sync |

---

## Formato del archivo de cola

Ruta: `%USERPROFILE%\.claude\pending-memories.jsonl` (Windows) / `~/.claude/pending-memories.jsonl` (Linux/macOS)

Una entrada JSON por línea:

```jsonl
{"timestamp":"2026-04-15T10:00:00Z","type":"memory","name":"Nombre","entityType":"Decision","observations":["obs1","obs2"]}
{"timestamp":"2026-04-15T10:00:01Z","type":"connection","from":"EntityA","to":"EntityB","relationType":"APLICA"}
```

---

## Task 1: brain-sync.ps1 — Script principal de sincronización

**Files:**
- Create: `brain-sync.ps1`

- [ ] **Step 1: Crear brain-sync.ps1**

El script debe:
1. Detectar la ruta del archivo de cola
2. Verificar que Neo4j responda (HTTP check)
3. Leer el JSONL línea a línea
4. Para cada entrada type=memory: ejecutar MERGE en Neo4j vía HTTP
5. Para cada entrada type=connection: ejecutar MERGE de relación
6. Eliminar entradas procesadas (reescribir el archivo con las fallidas)
7. Reportar resultado

- [ ] **Step 2: Verificar manualmente con un archivo de prueba**

Crear `%USERPROFILE%\.claude\pending-memories.jsonl` con una línea de test y ejecutar `.\brain-sync.ps1`.

- [ ] **Step 3: Commit**

```bash
git add brain-sync.ps1
git commit -m "feat: add brain-sync.ps1 — local memory queue sync to Neo4j"
```

---

## Task 2: brain-sync.bat y brain-sync.sh — Wrappers

**Files:**
- Create: `brain-sync.bat`
- Create: `brain-sync.sh`

- [ ] **Step 1: Crear brain-sync.bat** (llama a brain-sync.ps1)
- [ ] **Step 2: Crear brain-sync.sh** (versión bash con curl y jq)
- [ ] **Step 3: Commit**

```bash
git add brain-sync.bat brain-sync.sh
git commit -m "feat: add brain-sync wrappers for CMD and bash"
```

---

## Task 3: brain.bat y brain.ps1 — Agregar comando sync

**Files:**
- Modify: `brain.bat`
- Modify: `brain.ps1`

- [ ] **Step 1: Agregar `sync` a brain.bat**
- [ ] **Step 2: Agregar `sync` al ValidateSet y switch de brain.ps1**
- [ ] **Step 3: Commit**

```bash
git add brain.bat brain.ps1
git commit -m "feat: add sync command to brain.bat and brain.ps1"
```

---

## Task 4: CLAUDE.md — Protocolo de fallback local

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Agregar sección "Fallback de memoria local"**

Protocolo que Claude debe seguir:
- Intentar `mcp__team-brain__create_memory` o `mcp__team-brain__create_connection`
- Si falla: usar Write/Edit tool para appender al JSONL local
- Al inicio de sesión: verificar si el archivo existe y tiene contenido → avisar al dev

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add local memory fallback protocol to CLAUDE.md"
```

---

## Task 5: GUIA-PRACTICA.md — Documentar sync

**Files:**
- Modify: `GUIA-PRACTICA.md`

- [ ] **Step 1: Agregar sección sobre el comando sync y el fallback local**
- [ ] **Step 2: Commit**

```bash
git add GUIA-PRACTICA.md
git commit -m "docs: document local memory fallback and sync command"
```
