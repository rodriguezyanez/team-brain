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

*Team Brain KLAP BYSF · Guía de niveles v1.0 · Abril 2025*
