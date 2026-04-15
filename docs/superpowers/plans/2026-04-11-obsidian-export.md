# Obsidian Export — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Exportar el grafo Neo4j a archivos Markdown con `[[wikilinks]]` compatibles con Obsidian para visualizar el knowledge graph sin abrir Neo4j Browser.

**Architecture:** Tres scripts (`ps1`/`bat`/`sh`) consultan Neo4j via HTTP API, generan un archivo `.md` por nodo con propiedades como secciones y relaciones como `[[wikilinks]]`, y crean un `vault/README.md` como índice navegable. El directorio `vault/` se excluye del repositorio vía `.gitignore`.

**Tech Stack:** PowerShell (Invoke-RestMethod), bash + Python3, curl, Neo4j HTTP API REST

---

## Archivos a crear / modificar

| Acción | Archivo |
|--------|---------|
| Crear | `export-obsidian.ps1` |
| Crear | `export-obsidian.bat` |
| Crear | `export-obsidian.sh` |
| Modificar | `.gitignore` — agregar `vault/` |
| Modificar | `ONBOARDING.md` — sección Obsidian |
| Modificar | `ENRICHMENT-PLAN.md` — marcar Fase 7 completa |

---

## Task 1: export-obsidian.ps1 (implementación principal)

Consulta Neo4j, genera un `.md` por nodo, crea `vault/README.md`.

## Task 2: export-obsidian.bat

Wrapper que llama al ps1.

## Task 3: export-obsidian.sh

Implementación bash usando Python3 para parsear JSON.

## Task 4: Actualizaciones de documentos

- `.gitignore`: agregar `vault/`
- `ONBOARDING.md`: sección de Obsidian
- `ENRICHMENT-PLAN.md`: marcar Fase 7 completada (6→7/7)
