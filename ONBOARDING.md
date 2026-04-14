# Team Brain — Guía de niveles y onboarding

Guía para desarrolladores que se incorporan al ecosistema Team Brain.

---

## Sistema de niveles

Claude Code adapta su forma de explicar y generar código según el nivel declarado. Para activar un nivel escribe en cualquier momento:

```
nivel: initial
nivel: junior
nivel: dev
nivel: senior
```

Si no declaras un nivel, Claude evalúa tus preguntas y adapta automáticamente.

---

## ¿Qué cambia en cada nivel?

### initial — Estoy empezando con Spring Boot

Claude asume que sabes Java pero no Spring ni los patrones del equipo.

- Explica cada concepto antes de usarlo
- Muestra código completo con explicación línea por línea
- Usa analogías para conceptos complejos
- JavaDoc detallado con contexto de negocio y parámetros descritos didácticamente
- Propone ejercicios simples para validar cada concepto
- Ejemplo de lo que verás:

```
"Antes de ver el código, te explico qué es un @Bean: es un objeto
que Spring gestiona por ti — lo crea, lo inyecta donde lo necesites
y controla su ciclo de vida. Piensa en Spring como un almacén de
objetos que tú registras y él administra..."
```

---

### junior — Conozco Spring pero soy nuevo en este equipo

Claude asume que conoces Spring Boot, pero no los patrones específicos del equipo.

- Explica el "por qué" de cada decisión (por qué JdbcTemplate y no JPA, por qué envío Kafka síncrono, etc.)
- Compara con alternativas descartadas para que entiendas el razonamiento
- Código con comentarios en puntos clave
- JavaDoc con contexto de negocio
- Ejercicios de implementación guiada

---

### dev — Conozco el stack y los patrones (default)

El nivel estándar para desarrolladores con experiencia en el equipo.

- Contexto de negocio cuando es relevante
- Código limpio siguiendo los estándares
- JavaDoc estándar del equipo
- Claude consulta la memoria antes de proponer algo que ya esté decidido

---

### senior — Solo dime lo que necesito saber

Para desarrolladores con dominio completo del stack y los patrones.

- Va directo al punto
- Solo menciona contexto si hay algo no obvio
- JavaDoc conciso

---

## Flujo de onboarding

Si eres nuevo en el equipo, escribe en Claude Code:

```
onboarding
```

Claude te guiará por estos temas en orden, esperando tu confirmación en cada etapa:

1. Stack tecnológico — Java 21, Spring Boot 3.5.11, Gradle 9
2. Arquitectura de capas — el flujo completo de un mensaje Kafka
3. Estructura de paquetes — dónde vive cada clase
4. Patrones clave — Factory, Service Layer, Saga
5. Kafka — configuración, topics, DLQ, circuit breaker
6. Persistencia — JdbcTemplate, ConstantsQuery, paginación cursor-based
7. Convenciones — naming, logging, JavaDoc obligatorio
8. Reglas DO/DON'T — las 21 reglas de buenas prácticas y las 13 cosas que nunca hacer

Al final propone un ejercicio práctico adaptado a tu nivel.

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

## Prompts útiles por nivel

### Si eres initial o junior

```
Explícame cómo funciona el Factory Pattern de Kafka en este equipo
antes de que empiece a implementarlo
```

```
Quiero implementar un Repository. Guíame paso a paso
siguiendo los estándares del equipo
```

```
¿Por qué el equipo usa JdbcTemplate y no JPA?
```

### Si eres dev o senior

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

Agregá `use context7` a cualquier prompt cuando necesitás información precisa de una librería:

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

Combiná Context7 con SDD para implementaciones completas:
```
sdd: implementar WebClient para el servicio de autorizaciones
use context7 para los timeouts y la configuración de retry
```

---

## SDD — Cómo implementar features con el equipo

SDD (Spec-Driven Development) es el flujo de trabajo del equipo para implementar cualquier feature o componente nuevo. En lugar de pedirle a Claude que "genere el código", le pedís que guíe el proceso en 5 fases.

### Cómo activarlo

Escribí en Claude Code:

```
sdd: [descripción de lo que querés construir]
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

### Cómo se ve por nivel

**Nivel initial — Estoy aprendiendo Spring Boot:**
```
sdd: quiero crear un repositorio para guardar órdenes de pago

→ Fase 1: Claude pregunta: "¿Qué campos tiene la orden de pago? ¿Hay
  alguna tabla ya creada? ¿Cuántos registros estimás que va a tener?"

→ Fase 2: Claude explica: "Vamos a crear XxxRepository con @Repository.
  El equipo usa JdbcTemplate en lugar de JPA porque [razón completa con
  analogía]. La estructura quedaría así: [paquete completo explicado]"

→ Fase 3: Claude verifica cada regla y te muestra un ✅ o ❌

→ Fase 4: Claude genera el código completo explicando cada línea

→ Fase 5: Claude genera el test y te propone un ejercicio de validación
```

**Nivel junior — Conozco Spring, nuevo en el equipo:**
```
sdd: implementar KafkaListener para el dominio de liquidaciones

→ Fase 1: Claude consulta la memoria del equipo y mapea:
  topics input/output/DLQ, tablas PostgreSQL, servicios externos

→ Fase 2: Claude propone componentes con justificación:
  "Usamos ErrorHandlingDeserializer porque... el equipo descartó X porque..."

→ Fase 3: Checklist validado con contexto de negocio en cada punto

→ Fase 4: Código con comentarios en puntos clave del estándar

→ Fase 5: Tests + confirmación de cobertura 95%
```

**Nivel dev — Conozco el stack y los patrones:**
```
sdd: agregar cursor-based pagination al LiquidacionRepository

→ Fase 1 + 2: Resumen rápido del contexto y propuesta directa

→ Fase 3: Checklist sin explicaciones largas

→ Fase 4: Código limpio, JavaDoc estándar

→ Fase 5: Confirmación con checklist compacto
```

**Nivel senior — Solo lo que necesito:**
```
sdd: refactorizar KafkaConfig del dominio de pagos para usar la clase base

→ Claude fluye por las fases automáticamente, solo te detiene si hay
  una decisión bloqueante o algo que contradice el estándar
```

### Tip: SDD vs prompt directo

| Si querés... | Usá... |
|---|---|
| Construir algo nuevo siguiendo el estándar | `sdd: [descripción]` |
| Entender cómo funciona algo existente | pregunta directa |
| Generar un skeleton rápido | `Genera el skeleton de un XxxKafkaListener` |
| Guardar una decisión en memoria | `Guarda en memoria: [decisión]` |

---

## Reglas que Claude verifica automáticamente

Antes de generar código, Claude consulta las reglas DO/DON'T guardadas en Neo4j. Si propones algo que contradice el estándar, te lo indicará:

- **Nivel initial/junior**: explicación del por qué con contexto de negocio
- **Nivel dev/senior**: mención breve de la regla y continúa

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

1. Hacés `git commit`
2. El hook obtiene el diff staged de archivos `.java` / `.kt`
3. Claude revisa el diff contra las 10 reglas
4. Si todo OK → `✅ Guardian Angel: commit aprobado` → commit procede
5. Si hay violaciones → `🚫 Guardian Angel bloqueó el commit` + detalle → commit cancelado

### Bypass para commits urgentes

```bash
git commit --no-verify -m "hotfix: corrección urgente en producción"
```

> Usá `--no-verify` solo en emergencias reales. El hook existe para proteger la calidad del código.

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

1. Abrí [Obsidian](https://obsidian.md/) (gratuito)
2. **Archivo → Abrir vault → seleccionar la carpeta `vault/`**
3. Abrí `README.md` para el mapa de navegación completo
4. Hacé clic en cualquier `[[wikilink]]` para navegar entre nodos

### Estructura del vault

Cada archivo contiene:
- **Tipo** del nodo (Standard, Stack, BestPractices, CodeTemplate, etc.)
- **Propiedades** del nodo como lista
- **Conecta con** — nodos que este nodo referencia (`[[wikilinks]]`)
- **Referenciado desde** — nodos que apuntan a este nodo

### Nota

`vault/` está en `.gitignore` y no se sube al repositorio. Es un artefacto local generado a demanda.

---

*Team Brain KLAP BYSF · Guía de niveles v1.0 · Abril 2025*
