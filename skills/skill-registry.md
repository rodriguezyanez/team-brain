# Team Brain — Skill Registry KLAP BYSF

> Fallback local del conocimiento del equipo cuando Neo4j no esta disponible.
> Este archivo es el punto de entrada. Leelo primero, luego ve al skill especifico.

---

## Que es el Skill Registry

El Skill Registry es el indice central del conocimiento codificado del equipo KLAP BYSF.
Cada skill es un archivo Markdown con templates, patrones y reglas listas para usar.

Cuando Neo4j (Team Brain) no esta disponible, estos archivos son la fuente de verdad local.
Cuando Neo4j SI esta disponible, los skills complementan la memoria del grafo con ejemplos concretos de codigo.

---

## Cuando usarlo

| Situacion | Accion |
|-----------|--------|
| Neo4j no responde | Lee el skill relevante antes de generar codigo |
| Inicio rapido sin contexto | Lee `skill-registry.md` (este archivo), luego el skill especifico |
| Onboarding de dev nuevo | Recorre los skills en el orden del indice de abajo |
| Code review | Verifica que el codigo generado sigue los templates de los skills |
| Duda sobre un patron | Busca en el skill antes de preguntar al equipo |

---

## Stack del equipo

| Componente | Version |
|------------|---------|
| Java | 21 |
| Spring Boot | 3.5.11 |
| Spring Cloud | 2025.0.0 |
| Gradle | 9 |
| Kafka | Confluent / MSK |
| Base de datos | PostgreSQL Aurora |
| Resilience | resilience4j 2.x |
| Lombok | ultima compatible con Java 21 |
| Testing | JUnit 5 + Mockito + AssertJ + MockWebServer |
| Cobertura | JaCoCo 95% minimo |
| Documentacion API | springdoc-openapi 2.8.12 |

---

## Reglas globales siempre activas

Estas reglas aplican a TODO el codigo generado, sin excepcion y sin necesidad de consultarlo en memoria.

### 1. JavaDoc OBLIGATORIO

JavaDoc en todos los metodos publicos. Sin excepcion. Formato:

```java
/**
 * [Descripcion del objetivo en una oracion].
 * [Contexto adicional si es necesario].
 *
 * @param nombre descripcion
 * @return descripcion (omitir si es void)
 * @throws XxxException cuando [condicion]
 */
```

### 2. JdbcTemplate — NUNCA JPA/Hibernate

El equipo usa `JdbcTemplate` con queries en constantes (`ConstantsQuery`).
JPA/Hibernate esta prohibido. No proponer ni generar codigo con `@Entity`, `@Repository` de Spring Data, ni `EntityManager`.

### 3. Kafka: enable.metrics.push=false

Todas las configuraciones Kafka deben incluir:
```java
props.put("enable.metrics.push", "false");
```

### 4. Kafka: max.poll.records=1

Todos los consumers Kafka deben configurar:
```java
props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, "1");
```
Procesamos un mensaje a la vez para garantizar orden y trazabilidad.

### 5. Paginacion cursor-based para tablas grandes

Para tablas con mas de 500 registros, usar paginacion cursor-based (por ID o timestamp), nunca `LIMIT/OFFSET` con paginas grandes.

### 6. Cobertura 95% con JaCoCo

El build falla si la cobertura es menor al 95%. Configurar en `build.gradle`:
```gradle
jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit { minimum = 0.95 }
        }
    }
}
check.dependsOn jacocoTestCoverageVerification
```

### 7. Naming obligatorio

| Componente | Patron |
|------------|--------|
| Interfaz de servicio | `XxxService` |
| Implementacion de servicio | `XxxServiceImpl` |
| Procesador (saga) | `XxxProcessor` / `XxxProcessorImpl` |
| Repositorio | `XxxRepository` |
| Consumer Kafka | `XxxKafkaListener` |
| Cliente HTTP | `XxxClient` |
| Configuracion | `XxxConfig` |
| Request/Response DTO | `XxxRequest` / `XxxResponse` |
| Entidad BD | `XxxEntity` |

---

## Indice de skills

| Skill | Archivo | Que contiene | Cuando usarlo |
|-------|---------|--------------|---------------|
| Kafka Config | `kafka-config.md` | Template `KafkaConsumerConfig` y `KafkaProducerConfig` con todas las props obligatorias | Al crear un nuevo dominio con Kafka |
| Kafka Listener | `kafka-listener.md` | Template `@KafkaListener` con circuit breaker, manejo de errores y DLQ | Al crear un consumer Kafka |
| Processor (Saga) | `processor.md` | Template del patron saga de 6 pasos con transicion de estados | Al crear la logica de procesamiento de un dominio |
| Repository | `repository.md` | Template `XxxRepository` con `JdbcTemplate`, `ConstantsQuery` y cursor-based pagination | Al crear acceso a datos |
| WebClient | `webclient.md` | Template `XxxClient` con retry, timeout, manejo de 4xx/5xx y circuit breaker | Al integrar un servicio externo via HTTP |
| Exceptions | `exceptions.md` | Jerarquia de excepciones del dominio: `XxxException`, `XxxNotFoundException`, `XxxClientException` | Al definir el manejo de errores de un nuevo dominio |
| Testing | `testing.md` | Template de tests con Mockito (AAA), test de repositorio y test de cliente con MockWebServer | Al escribir tests unitarios |
| OpenAPI | `openapi.md` | Template `OpenApiConfig` para perfiles local/develop, anotaciones de controllers | Al exponer la API con Swagger |

---

## Flujo de trabajo recomendado

Al crear un nuevo dominio o componente, seguir este orden:

```
1. exceptions.md     → Define las excepciones del dominio
2. repository.md     → Define el acceso a datos
3. processor.md      → Define la logica de negocio (saga)
4. kafka-config.md   → Configura Kafka del dominio
5. kafka-listener.md → Crea el consumer
6. webclient.md      → Si hay integracion HTTP externa
7. openapi.md        → Si el servicio expone endpoints REST
8. testing.md        → Escribe los tests de cada componente
```

Al agregar solo un componente puntual, ir directamente al skill correspondiente.

---

## Guia de uso

1. **Lee este archivo primero** para identificar el skill que necesitas.
2. **Abre el skill especifico** (`skills/xxx.md`) — contiene el template completo listo para adaptar.
3. **Sustituye los placeholders** `Xxx` / `{dominio}` / `{descripcion}` con los valores reales del dominio.
4. **Verifica las reglas globales** de esta pagina antes de entregar el codigo.
5. **Si Neo4j esta disponible**, consulta tambien `memory_search` para verificar decisiones previas del equipo sobre ese dominio especifico.

---

*Skill Registry v2.0 · KLAP BYSF · Abril 2025 · 8 skills disponibles*
