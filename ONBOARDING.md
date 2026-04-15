# Team Brain — Guía de onboarding

Guía para desarrolladores que se incorporan al ecosistema Team Brain.

---

## Cómo trabaja Claude con este equipo

Claude asume conocimiento completo del stack (Spring Boot, Kafka, patrones del equipo). Va directo al punto, solo menciona contexto cuando hay algo no obvio o una decisión que rompe el estándar.

---

## Instalación y desinstalación

El instalador unificado (`setup.bat` / `setup.sh`) hace todo en un comando. Antes de tocar cualquier archivo, crea un backup completo de tu configuración de Claude Code en `~/.claude/team-brain-backup/`.

Para desinstalar y dejar todo como estaba:

```bat
# Windows
setup.bat --uninstall
```

```bash
# Linux / macOS
./setup.sh --uninstall
```

Restaura exactamente: `.claude.json`, `settings.json`, skills y `CLAUDE.md`. Docker, Node.js y Claude Code no se tocan.

---

## Primeros pasos al incorporarte

Al abrir Claude Code por primera vez, indica el proyecto en el que vas a trabajar. Claude carga el contexto desde Neo4j y aplica el Standard KLAP BYSF automáticamente.

---

## JavaDoc — por qué es obligatorio

Todos los métodos públicos deben tener JavaDoc. El equipo lo adoptó por tres razones:

1. Los microservicios tienen múltiples dominios y devs distintos los tocan — el JavaDoc reduce el tiempo de entendimiento
2. Sirve como documentación viva: el IDE muestra el JavaDoc al hacer hover sobre cualquier método
3. Obliga a pensar en el objetivo del método antes de implementarlo

Formato esperado:

```java
/**
 * Procesa la orden de pago recibida desde Kafka y coordina el flujo completo:
 * validación, consulta al sistema legado, persistencia y publicación de resultado.
 *
 * @param input DTO con los datos de la orden de pago recibida del topic input
 * @return DTO de salida con el resultado del procesamiento y estado final
 * @throws XxxException si falla la consulta al sistema legado o la persistencia
 */
public XxxOutputDto procesarOrdenPago(XxxInputDto input) {
```

---

## Prompts útiles

```
Antes de tocar el módulo de pagos, revisa la memoria del equipo
y dime qué decisiones se han tomado sobre él
```

```
Genera el skeleton de un KafkaListener para el dominio de tarifas
siguiendo el estándar del equipo
```

```
Guarda en memoria la decisión: usaremos cursor-based pagination
en la tabla de liquidaciones. Motivo: tiene más de 2M de registros
```

---

## Context7 — Documentación actualizada del stack

El equipo tiene instalado **Context7**, un MCP que provee documentación en tiempo real de las librerías del stack. Sirve para evitar que Claude genere código basado en versiones antiguas de las APIs.

### Cómo usarlo

Agrega `use context7` a cualquier prompt cuando necesitas información precisa de una librería:

```
use context7, ¿cómo configuro un CircuitBreaker con Resilience4j 2.2.0?
```

```
use context7, ¿cuáles son las propiedades de spring.kafka.consumer en Spring Boot 3.5.11?
```

```
use context7, ¿cómo hago retry con WebClient en Spring WebFlux?
```

### Librerías del stack cubiertas

| Librería | Versión |
|----------|---------|
| Spring Boot | 3.5.11 |
| Spring Cloud | 2025.0.0 |
| Spring Kafka | (incluido en Spring Boot 3.5.11) |
| Resilience4j | 2.2.0 |
| Spring WebFlux (WebClient) | (incluido en Spring Boot 3.5.11) |
| springdoc-openapi | 2.8.12 |
| PostgreSQL JDBC | 42.7.2 |

### Tip

Combina Context7 con SDD para implementaciones completas:
```
sdd: implementar WebClient para el servicio de autorizaciones
use context7 para los timeouts y la configuración de retry
```

---

## SDD — Cómo implementar features con el equipo

SDD (Spec-Driven Development) es el flujo de trabajo del equipo para implementar cualquier feature o componente nuevo. En lugar de pedirle a Claude que "genere el código", le pedís que guíe el proceso en 5 fases.

### Cómo activarlo

Escribe en Claude Code:

```
sdd: [descripción de lo que quieres construir]
```

Ejemplos:

```
sdd: implementar KafkaListener para el dominio de tarifas
```
```
sdd: agregar endpoint para consultar liquidaciones pendientes
```
```
sdd: crear WebClient para el servicio de autorizaciones externas
```

### Las 5 fases

**Fase 1 — Explorar** → Claude lee el dominio y mapea qué necesita construirse

**Fase 2 — Proponer** → Claude presenta el enfoque antes de escribir código

**Fase 3 — Validar** → Claude verifica que la propuesta cumple las reglas del equipo

**Fase 4 — Implementar** → Claude escribe el código siguiendo los templates del equipo

**Fase 5 — Verificar** → Claude confirma que todo cumple: tests, JavaDoc, naming, reglas críticas

### Ejemplo de flujo

```
sdd: agregar cursor-based pagination al LiquidacionRepository

→ Fase 1 + 2: Contexto desde Neo4j y propuesta directa
→ Fase 3: Checklist contra reglas DO/DON'T
→ Fase 4: Código limpio, JavaDoc estándar
→ Fase 5: Verificación con checklist explícito
```

### Tip: SDD vs prompt directo

| Si quieres... | Usa... |
|---|---|
| Construir algo nuevo siguiendo el estándar | `sdd: [descripción]` |
| Entender cómo funciona algo existente | pregunta directa |
| Generar un skeleton rápido | `Genera el skeleton de un XxxKafkaListener` |
| Guardar una decisión en memoria | `Guarda en memoria: [decisión]` |

---

## Reglas que Claude verifica automáticamente

Antes de generar código, Claude consulta las reglas DO/DON'T guardadas en Neo4j. Si propones algo que contradice el estándar, menciona la regla brevemente y continúa.

Ejemplos de advertencias que verás:

```
⚠️ El equipo tiene una regla contra el uso de JPA/Hibernate (DON'T #4).
La arquitectura usa JdbcTemplate puro. ¿Quieres que genere el Repository
con JdbcTemplate en su lugar?
```

```
⚠️ enable.metrics.push=false es crítico (DO #11). Si lo omites,
el consumer en MSK/Confluent tendrá OOM progresivo en producción.
Lo agrego a la configuración.
```

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

1. Haces `git commit`
2. El hook obtiene el diff staged de archivos `.java` / `.kt`
3. Claude revisa el diff contra las 10 reglas
4. Si todo OK → `✅ Guardian Angel: commit aprobado` → commit procede
5. Si hay violaciones → `🚫 Guardian Angel bloqueó el commit` + detalle → commit cancelado

### Bypass para commits urgentes

```bash
git commit --no-verify -m "hotfix: corrección urgente en producción"
```

> Usa `--no-verify` solo en emergencias reales. El hook existe para proteger la calidad del código.

### Desinstalar

```bash
rm .git/hooks/pre-commit
rm .git/hooks/review-prompt.md
```

---

## Obsidian Vault — Visualizar el grafo sin Neo4j Browser

Podés exportar el grafo completo de Neo4j a archivos Markdown con `[[wikilinks]]` y abrirlos en **Obsidian** para navegar el knowledge graph visualmente.

### Exportar

```bash
# Windows PowerShell
.\export-obsidian.ps1

# Windows CMD
export-obsidian.bat

# Linux / macOS (requiere Python3)
./export-obsidian.sh
```

Se genera una carpeta `vault/` con un archivo `.md` por cada nodo del grafo.

### Abrir en Obsidian

1. Abre [Obsidian](https://obsidian.md/) (gratuito)
2. **Archivo → Abrir vault → seleccionar la carpeta `vault/`**
3. Abre `README.md` para el mapa de navegación completo
4. Haz clic en cualquier `[[wikilink]]` para navegar entre nodos

### Estructura del vault

Cada archivo contiene:
- **Tipo** del nodo (Standard, Stack, BestPractices, CodeTemplate, etc.)
- **Propiedades** del nodo como lista
- **Conecta con** — nodos que este nodo referencia (`[[wikilinks]]`)
- **Referenciado desde** — nodos que apuntan a este nodo

### Nota

`vault/` está en `.gitignore` y no se sube al repositorio. Es un artefacto local generado a demanda.

---

*Team Brain KLAP BYSF · Guía de onboarding v2.0 · Abril 2026*
