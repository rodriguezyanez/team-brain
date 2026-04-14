# Team Brain — Plan de enriquecimiento

> Ejecutar este plan desde Claude Code en el directorio `team-brain/`.
> Claude marcará cada tarea como completada a medida que avanza.
> Estado general: **7 / 7 fases completadas**

---

## Cómo usar este plan

1. Abre Claude Code en el directorio `team-brain/`
2. Escribe: `Lee ENRICHMENT-PLAN.md y ejecuta la siguiente fase pendiente`
3. Claude ejecutará la fase, generará los archivos y marcará las tareas completadas
4. Puedes continuar con `ejecuta la siguiente fase` o pausar y retomar en otra sesión

Claude actualiza este archivo marcando `[ ]` → `[x]` a medida que completa tareas.

---

## Fases del plan

### FASE 1 — Instalador unificado `setup.bat` / `setup.ps1` / `setup.sh`
**Prioridad**: Alta | **Esfuerzo**: Bajo | **Estado**: `[x] Completada`

Reemplaza el proceso manual de 5 pasos por un único script que orqueste todo
el setup de primer uso, detecte prerequisitos y guíe al dev si algo falta.

#### Tareas

- [x] Crear `setup.bat` que ejecute en orden: verificar prerequisitos → `brain.bat up` → esperar Neo4j → `init-brain.bat` → `enrich-brain.bat` → registrar MCP → copiar `CLAUDE.md`
- [x] Crear `setup.ps1` equivalente con output con colores y manejo de errores robusto
- [x] Crear `setup.sh` equivalente para Linux / macOS con output con colores
- [x] Agregar verificación de prerequisitos: Docker Desktop corriendo, Node >= 18, Claude Code instalado
- [x] Agregar detección automática de la password desde `docker-compose.yml` (no hardcodear)
- [x] Agregar resumen final del estado: qué quedó instalado, qué falló, próximos pasos
- [x] Actualizar `README.md` y `CONTEXT.md` con el nuevo flujo de instalación en un comando
- [x] Actualizar `team-brain-guia-inicio.md` con la sección del instalador unificado

**Prompt para Claude Code:**
```
Lee ENRICHMENT-PLAN.md. Ejecuta la Fase 1 completa:
crea setup.bat y setup.ps1 que orquesten todo el setup de primer uso de Team Brain.
Al terminar marca todas las tareas de la Fase 1 como completadas en este archivo.
```

---

### FASE 2 — Skill registry local (`~/.claude/skills/`)
**Prioridad**: Alta | **Esfuerzo**: Bajo | **Estado**: `[x] Completada`

Exporta los templates de código como archivos Markdown en `~/.claude/skills/`
para que el agente pueda accederlos incluso sin Neo4j corriendo. Son el fallback
local del conocimiento del equipo.

#### Tareas

- [x] Crear `skills/kafka-config.md` — Template KafkaConfig con estructura, reglas y skeleton
- [x] Crear `skills/kafka-listener.md` — Template Listener con circuit breaker y manejo de errores
- [x] Crear `skills/processor.md` — Template Processor saga pattern con los 6 pasos
- [x] Crear `skills/repository.md` — Template Repository JdbcTemplate con cursor-based pagination
- [x] Crear `skills/webclient.md` — Template WebClient con retry y manejo de 4xx/5xx
- [x] Crear `skills/exceptions.md` — Template jerarquía de excepciones del dominio
- [x] Crear `skills/testing.md` — Template test con Mockito, patrón Arrange-Act-Assert y MockWebServer
- [x] Crear `skills/openapi.md` — Template OpenApiConfig con anotaciones estándar
- [x] Crear `skills/skill-registry.md` — Índice de todos los skills con descripción y cuándo usarlos
- [x] Crear `install-skills.bat` — Copia los skills a `%USERPROFILE%\.claude\skills\`
- [x] Crear `install-skills.ps1` — Equivalente PowerShell con output con colores
- [x] Crear `install-skills.sh` — Equivalente Linux/macOS (`~/.claude/skills/`)
- [x] Actualizar `CLAUDE.md` para que busque skills locales como fallback cuando Neo4j no está disponible
- [x] Integrar `install-skills` en `setup.bat`, `setup.ps1` y `setup.sh`

**Prompt para Claude Code:**
```
Lee ENRICHMENT-PLAN.md. Ejecuta la Fase 2 completa:
crea los skill files en formato Markdown para ~/.claude/skills/ basándote en
los templates de ARQUITECTURA_REFERENCIA.md y los nodos cargados en Neo4j.
Al terminar marca todas las tareas de la Fase 2 como completadas en este archivo.
```

---

### FASE 3 — SDD simplificado para microservicios KLAP BYSF
**Prioridad**: Alta | **Esfuerzo**: Medio | **Estado**: `[x] Completada`

Implementa un flujo Spec-Driven Development adaptado al contexto de microservicios
event-driven de KLAP BYSF. No replica las 9 fases de gentle-ai — usa 5 fases
ajustadas al dominio.

#### Tareas

- [x] Crear `skills/sdd-microservice.md` — Skill que define las 5 fases SDD para KLAP BYSF:
  - Fase 1 Explorar: leer el dominio, consultar memoria del equipo, mapear dependencias
  - Fase 2 Proponer: enfoque de implementación con justificación arquitectónica
  - Fase 3 Validar: verificar propuesta contra reglas DO/DON'T antes de implementar
  - Fase 4 Implementar: código siguiendo templates y convenciones del equipo
  - Fase 5 Verificar: tests 95%+ cobertura, JavaDoc completo, sin violaciones de estándar
- [x] Actualizar `CLAUDE.md` con sección SDD: activación con `sdd: [descripción]`, comportamiento por fase, criterios de completitud por nivel
- [x] Crear `skills/sdd-checklist.md` — Checklist de validación por fase para que Claude lo consulte automáticamente
- [x] Documentar en `ONBOARDING.md` cómo usar SDD con ejemplos para cada nivel (`initial` a `senior`)

**Prompt para Claude Code:**
```
Lee ENRICHMENT-PLAN.md y ARQUITECTURA_REFERENCIA.md. Ejecuta la Fase 3 completa:
implementa el flujo SDD de 5 fases adaptado a microservicios KLAP BYSF.
Al terminar marca todas las tareas de la Fase 3 como completadas en este archivo.
```

---

### FASE 4 — Context7 MCP para documentación en tiempo real
**Prioridad**: Media | **Esfuerzo**: Bajo | **Estado**: `[x] Completada`

Integra Context7 como segundo MCP server para que Claude tenga acceso a la
documentación actualizada de Spring Boot 3.5, Kafka, Resilience4j y otras
librerías del stack, evitando código basado en APIs de versiones antiguas.

#### Tareas

- [x] Verificar que `npx -y @upstash/context7-mcp` funciona en el entorno
- [x] Crear `install-context7.bat` — registra Context7 en Claude Code con `--scope user`
- [x] Crear `install-context7.ps1` — equivalente PowerShell
- [x] Crear `install-context7.sh` — equivalente Linux/macOS
- [x] Actualizar `CLAUDE.md` con instrucción: agregar `use context7` cuando se trabaje con Spring Boot, Kafka, Resilience4j o WebClient para obtener docs de la versión exacta
- [x] Agregar al `ONBOARDING.md` la sección de Context7 con ejemplos de uso
- [x] Integrar `install-context7` en `setup.bat` y `setup.ps1` como paso opcional
- [x] Actualizar `brain.bat mcp` y `brain.ps1 mcp` para que registren también Context7

**Prompt para Claude Code:**
```
Lee ENRICHMENT-PLAN.md. Ejecuta la Fase 4 completa:
integra Context7 MCP al ecosistema Team Brain con scripts de instalación
para Windows y Linux/macOS.
Al terminar marca todas las tareas de la Fase 4 como completadas en este archivo.
```

---

### FASE 5 — Guardian Angel (code review automático pre-commit)
**Prioridad**: Media | **Esfuerzo**: Medio | **Estado**: `[x] Completada`

Implementa un hook git pre-commit que revisa cada cambio contra las reglas
DO/DON'T del equipo antes de permitir el commit. Usa Claude Code CLI en modo
no-interactivo.

#### Tareas

- [x] Crear `hooks/pre-commit.sh` — hook bash que llama a Claude con el diff staged y las reglas del equipo
- [x] Crear `hooks/pre-commit.bat` — equivalente Windows CMD
- [x] Crear `hooks/pre-commit.ps1` — equivalente PowerShell
- [x] Crear `install-hooks.sh` — instala el hook en `.git/hooks/` del proyecto activo
- [x] Crear `install-hooks.bat` / `install-hooks.ps1` — equivalentes Windows
- [x] Definir el prompt de revisión en `hooks/review-prompt.md`: lista de verificaciones (JavaDoc, no JPA, no SQL hardcodeado, `enable.metrics.push=false`, naming conventions, etc.)
- [x] Agregar modo `--bypass` para commits urgentes: `git commit --no-verify`
- [x] Documentar en `ONBOARDING.md` cómo instalar y desactivar el hook
- [x] Agregar `install-hooks` como paso opcional en `setup.bat`

**Prompt para Claude Code:**
```
Lee ENRICHMENT-PLAN.md y los archivos de convenciones del equipo en Neo4j o en ARQUITECTURA_REFERENCIA.md.
Ejecuta la Fase 5 completa: implementa el hook pre-commit GGA para KLAP BYSF.
Al terminar marca todas las tareas de la Fase 5 como completadas en este archivo.
```

---

### FASE 6 — `brain-update.bat` (sincronización incremental de Neo4j)
**Prioridad**: Media | **Esfuerzo**: Bajo | **Estado**: `[x] Completada`

Cuando se actualice `ARQUITECTURA_REFERENCIA.md`, hoy hay que re-ejecutar
`enrich-brain.bat` completo. Este script actualiza solo los nodos del Standard
sin borrar la memoria acumulada del equipo (decisiones, bugs, patterns).

#### Tareas

- [x] Crear `brain-update.bat` — actualiza nodos Standard/Stack/Kafka/Templates/DO/DONT usando `MERGE` (no borra nodos de tipo Decision, Fix, Pattern, Convention, Developer, Service)
- [x] Crear `brain-update.ps1` — equivalente PowerShell con output detallado de qué cambió
- [x] Crear `brain-update.sh` — equivalente Linux/macOS
- [x] Agregar timestamp de última actualización como propiedad en el nodo `Standard KLAP BYSF`
- [x] Agregar al `brain.bat` el comando `brain.bat update` como alias de `brain-update.bat`
- [x] Agregar al `brain.ps1` el comando `.\brain.ps1 update` equivalente
- [x] Documentar en `CONTEXT.md` y `README.md` el flujo de actualización cuando cambia la arquitectura de referencia

**Prompt para Claude Code:**
```
Lee ENRICHMENT-PLAN.md y enrich-brain.bat. Ejecuta la Fase 6 completa:
crea brain-update.bat/ps1/sh que sincronice incrementalmente Neo4j
preservando la memoria acumulada del equipo.
Al terminar marca todas las tareas de la Fase 6 como completadas en este archivo.
```

---

### FASE 7 — Exportación a Obsidian / visualización externa
**Prioridad**: Baja | **Esfuerzo**: Alto | **Estado**: `[x] Completada`

Exporta el grafo Neo4j a archivos Markdown con links `[[wikilink]]` compatibles
con Obsidian, para que el equipo pueda navegar el conocimiento sin abrir Neo4j Browser.

#### Tareas

- [x] Crear `export-obsidian.bat` — exporta todos los nodos `Entity` de Neo4j a archivos `.md` en `./vault/`
- [x] Crear `export-obsidian.ps1` — equivalente PowerShell
- [x] Crear `export-obsidian.sh` — equivalente Linux/macOS
- [x] Formato de exportación: cada nodo → un archivo `NombreNodo.md` con propiedades como secciones y relaciones como `[[wikilinks]]`
- [x] Agregar índice `vault/README.md` con mapa de navegación del grafo
- [x] Documentar en `ONBOARDING.md` cómo abrir el vault en Obsidian
- [x] Agregar `.gitignore` entries para excluir `vault/` del repositorio (datos sensibles)

**Prompt para Claude Code:**
```
Lee ENRICHMENT-PLAN.md. Ejecuta la Fase 7 completa:
crea los scripts de exportación Neo4j → Obsidian vault para Team Brain KLAP BYSF.
Al terminar marca todas las tareas de la Fase 7 como completadas en este archivo.
```

---

## Resumen de progreso

| Fase | Descripción | Prioridad | Estado |
|------|-------------|-----------|--------|
| 1 | Instalador unificado `setup` | Alta | `[x] Completada` |
| 2 | Skill registry local `~/.claude/skills/` | Alta | `[x] Completada` |
| 3 | SDD simplificado para microservicios | Alta | `[x] Completada` |
| 4 | Context7 MCP — docs en tiempo real | Media | `[x] Completada` |
| 5 | Guardian Angel — code review pre-commit | Media | `[x] Completada` |
| 6 | `brain-update` — sincronización incremental | Media | `[x] Completada` |
| 7 | Exportación a Obsidian | Baja | `[x] Completada` |

**Completadas: 7 / 7** 🎉

---

## Orden de ejecución recomendado

```
Sesión 1: Fase 1 + Fase 2   (instalador + skills locales — base operacional)
Sesión 2: Fase 3            (SDD — cambio más impactante en el flujo de trabajo)
Sesión 3: Fase 4 + Fase 6   (Context7 + brain-update — mejoras rápidas)
Sesión 4: Fase 5            (Guardian Angel — requiere más validación en el equipo)
Sesión 5: Fase 7            (Obsidian — mejora de visualización, no urgente)
```

---

## Notas para Claude Code

- Antes de ejecutar cada fase, lee `CONTEXT.md` para entender el estado actual del ecosistema
- Al completar cada tarea individual, actualiza inmediatamente `[ ]` → `[x]` en este archivo
- Al completar una fase completa, actualiza la tabla de resumen y el contador de completadas
- Si una tarea requiere información que no está disponible (ej: password de Neo4j), leer `docker-compose.yml`
- Los archivos nuevos van siempre en la raíz de `team-brain/` salvo que la tarea indique otra ubicación
- Mantener compatibilidad: cada nuevo script `.bat` debe tener su equivalente `.ps1` y `.sh`

---

*Team Brain KLAP BYSF — Plan de enriquecimiento v1.0 — Abril 2026*
*Basado en: informe-comparativo.md vs gentle-ai (Gentleman-Programming)*
