# Skill: Jerarquía de Excepciones

## Cuándo usar este skill

Cuando necesites crear o manejar excepciones en un dominio de KLAP BYSF.
Aplica en services, repositories, clientes HTTP y Kafka listeners.

---

## Jerarquía completa

```
RuntimeException
├── XxxException                      ← base del dominio (siempre extender esta)
│   ├── XxxClientException            ← errores de API externa (statusCode + responseBody)
│   └── XxxPersistenceException       ← errores de DB (envuelve DataAccessException)
├── NonRetryableClientDataException   ← errores de datos irrecuperables → DLQ sin reintentos
└── KafkaMessageException             ← errores de serialización/deserialización Kafka
```

---

## Reglas del equipo

**DO:**
- `XxxException`: siempre crear dos constructores: `(String message)` y `(String message, Throwable cause)`
- `XxxClientException`: incluir `statusCode` (int) y `responseBody` (String) como campos
- `XxxPersistenceException`: siempre envolver `DataAccessException` — nunca dejarla escapar del repository
- `NonRetryableClientDataException`: usarla en el listener cuando los datos del mensaje son inválidos (determinista) → va a DLQ sin reintentos
- Ubicar todas las excepciones en `dominio/{nombre_dominio}/exceptions/`

**DON'T:**
- No lanzar `XxxClientException` desde el Kafka listener para errores de infraestructura (timeout, DB caída) — esos SÍ deben reintentarse
- No extender `Exception` (checked) — todas las excepciones del dominio son `RuntimeException`
- No usar `RuntimeException` directo — siempre usar la excepción del dominio correspondiente
- No lanzar `NonRetryableClientDataException` para errores transitorios (red caída, DB no disponible)
- No capturar `KafkaMessageException` manualmente — la maneja `ErrorHandlingDeserializer` automáticamente

---

## Cuándo usar cada excepción

| Situación | Excepción a lanzar |
|-----------|-------------------|
| API externa devuelve 4xx | `XxxClientException(msg, 4xx, body)` |
| API externa devuelve 5xx | `XxxClientException(msg, 5xx, body)` |
| `DataAccessException` en repository | `XxxPersistenceException(msg, cause)` |
| Payload de Kafka malformado | `NonRetryableClientDataException` |
| Business rule violation determinista | `NonRetryableClientDataException` |
| Datos del mensaje inválidos (null, formato incorrecto) | `NonRetryableClientDataException` |
| Falla de serialización JSON en Kafka | `KafkaMessageException` (automático) |

---

## Dónde viven

```
src/main/java/cl/klap/bysf/{modulo}/{aplicacion}/dominio/{nombre_dominio}/
└── exceptions/
    ├── XxxException.java
    ├── XxxClientException.java
    ├── XxxPersistenceException.java
    ├── NonRetryableClientDataException.java
    └── KafkaMessageException.java
```

---

## Ejemplo completo

### `LiquidacionException.java` — Base del dominio

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions;

/**
 * Excepción base del dominio Liquidacion.
 * Todas las excepciones del dominio extienden esta clase para permitir
 * manejo genérico en los puntos de entrada (listeners, controllers).
 */
public class LiquidacionException extends RuntimeException {

    /**
     * Crea una excepción con un mensaje descriptivo.
     *
     * @param message descripción del error ocurrido
     */
    public LiquidacionException(String message) {
        super(message);
    }

    /**
     * Crea una excepción con mensaje y causa original para preservar el stack trace.
     *
     * @param message descripción del error ocurrido
     * @param cause   excepción original que causó este error
     */
    public LiquidacionException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

### `LiquidacionClientException.java` — Errores de API externa

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions;

/**
 * Excepción lanzada cuando una API externa responde con error (4xx o 5xx).
 * Incluye el statusCode HTTP y el body de la respuesta para facilitar el diagnóstico.
 * Se usa en {@code XxxClient} y debe capturarse en el service o listener.
 */
public class LiquidacionClientException extends LiquidacionException {

    /** Código de estado HTTP retornado por la API externa. */
    private final int statusCode;

    /** Cuerpo de la respuesta de error (puede estar truncado para evitar logs muy grandes). */
    private final String responseBody;

    /**
     * Crea una excepción de cliente con el contexto completo del error HTTP.
     *
     * @param message      descripción del error
     * @param statusCode   código HTTP retornado por la API externa (ej: 400, 404, 500)
     * @param responseBody body de la respuesta de error para diagnóstico
     */
    public LiquidacionClientException(String message, int statusCode, String responseBody) {
        super(message);
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    /**
     * Crea una excepción de cliente con causa original (para errores de timeout o red).
     *
     * @param message      descripción del error
     * @param statusCode   código HTTP (puede ser 0 si no hay respuesta HTTP)
     * @param responseBody body disponible (puede ser vacío en errores de red)
     * @param cause        excepción original que causó el error
     */
    public LiquidacionClientException(String message, int statusCode, String responseBody, Throwable cause) {
        super(message, cause);
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    /**
     * Retorna el código de estado HTTP de la respuesta de error.
     *
     * @return código HTTP (ej: 400, 404, 500, 503)
     */
    public int getStatusCode() {
        return statusCode;
    }

    /**
     * Retorna el body de la respuesta de error recibida de la API externa.
     *
     * @return cuerpo de la respuesta, vacío si no hubo respuesta HTTP
     */
    public String getResponseBody() {
        return responseBody;
    }

    @Override
    public String toString() {
        return "LiquidacionClientException{statusCode=" + statusCode +
               ", responseBody='" + responseBody + "', message='" + getMessage() + "'}";
    }
}
```

### `LiquidacionPersistenceException.java` — Errores de base de datos

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions;

/**
 * Excepción lanzada cuando ocurre un error de acceso a la base de datos en el dominio Liquidacion.
 * Envuelve {@link org.springframework.dao.DataAccessException} para desacoplar el dominio
 * de los detalles de implementación de Spring JDBC.
 */
public class LiquidacionPersistenceException extends LiquidacionException {

    /**
     * Crea una excepción de persistencia con mensaje descriptivo.
     * Usar cuando no hay excepción original disponible (caso poco frecuente).
     *
     * @param message descripción del error de base de datos
     */
    public LiquidacionPersistenceException(String message) {
        super(message);
    }

    /**
     * Crea una excepción de persistencia envolviendo la excepción original de Spring JDBC.
     * Esta es la forma preferida — siempre pasar la causa para preservar el stack trace.
     *
     * @param message descripción del error de base de datos
     * @param cause   {@link org.springframework.dao.DataAccessException} original
     */
    public LiquidacionPersistenceException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

### `NonRetryableClientDataException.java` — Errores irrecuperables (DLQ)

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions;

/**
 * Excepción para errores de datos irrecuperables en mensajes Kafka.
 * Cuando se lanza en un listener, el mensaje NO se reintenta y va directamente a la DLQ.
 *
 * Usar cuando:
 * - El payload del mensaje es malformado o incompleto
 * - Una business rule validation falla de forma determinista
 * - Los datos del mensaje son inválidos y no cambiarán con reintentos
 *
 * NO usar para errores de infraestructura (DB caída, API externa no disponible)
 * — esos errores sí deben reintentarse.
 */
public class NonRetryableClientDataException extends RuntimeException {

    /**
     * Crea una excepción no reintentable con un mensaje descriptivo del error de datos.
     *
     * @param message descripción del error de datos que impide el procesamiento
     */
    public NonRetryableClientDataException(String message) {
        super(message);
    }

    /**
     * Crea una excepción no reintentable con mensaje y causa original.
     *
     * @param message descripción del error de datos
     * @param cause   excepción original que detectó el problema de datos
     */
    public NonRetryableClientDataException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

### `KafkaMessageException.java` — Errores de serialización

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions;

/**
 * Excepción para errores de serialización y deserialización de mensajes Kafka.
 * En la mayoría de los casos es manejada automáticamente por {@code ErrorHandlingDeserializer}
 * de Spring Kafka — no es necesario capturarla manualmente en el listener.
 *
 * Solo instanciar directamente si se implementa serialización/deserialización custom.
 */
public class KafkaMessageException extends RuntimeException {

    /**
     * Crea una excepción de Kafka con mensaje descriptivo del error de serialización.
     *
     * @param message descripción del error de serialización o deserialización
     */
    public KafkaMessageException(String message) {
        super(message);
    }

    /**
     * Crea una excepción de Kafka con mensaje y causa original.
     *
     * @param message descripción del error
     * @param cause   excepción original del proceso de serialización
     */
    public KafkaMessageException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

---

## Cómo usarlas en el Kafka Listener

```java
@KafkaListener(topics = "${kafka.topics.liquidacion}")
public void procesar(ConsumerRecord<String, LiquidacionEvent> record) {
    try {
        LiquidacionEvent event = record.value();

        // Validar datos del mensaje — si son inválidos, va a DLQ sin reintentar
        if (event == null || event.getId() == null) {
            throw new NonRetryableClientDataException(
                    "Mensaje inválido: event o id es null en offset=" + record.offset());
        }

        liquidacionService.procesar(event);

    } catch (NonRetryableClientDataException e) {
        // Error de datos → DLQ, NO reintentar
        // El DefaultErrorHandler configurado con NonRetryableClientDataException lo envía a DLQ
        log.error("Error de datos irrecuperable, enviando a DLQ: {}", e.getMessage());
        throw e;

    } catch (LiquidacionClientException e) {
        // Error de API externa → puede ser transitorio si es 5xx → reintentar
        // Si es 4xx (datos inválidos que vinieron de nosotros) → considerar NonRetryableClientDataException
        log.error("Error de API externa: statusCode={}, body={}", e.getStatusCode(), e.getResponseBody());
        throw e; // El DefaultErrorHandler decide si reintenta según la configuración

    } catch (LiquidacionPersistenceException e) {
        // Error de DB → transitorio → reintentar
        log.error("Error de persistencia procesando liquidacion: {}", e.getMessage(), e);
        throw e;
    }
}
```

---

## Anti-patrones a evitar

- **Extender `Exception` (checked):** todas las excepciones del dominio son `RuntimeException` — nunca `Exception`
- **Usar `RuntimeException` directo:** siempre usar la excepción del dominio (`XxxException` o derivadas)
- **`NonRetryableClientDataException` para errores de infraestructura:** si la DB está caída, el mensaje SÍ debe reintentarse
- **`XxxClientException` desde el listener:** confunde errores de datos con errores de comunicación
- **Capturar `KafkaMessageException` manualmente:** `ErrorHandlingDeserializer` la maneja; interceptarla puede romper el flujo de DLQ
- **Perder la causa original:** siempre pasar el `Throwable cause` en el constructor para no romper el stack trace
- **Excepciones fuera de `exceptions/`:** no dispersar clases de excepción en otros paquetes del dominio
