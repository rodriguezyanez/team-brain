# Skill: Kafka Listener

## Cuándo usar este skill

Cuando necesitas implementar un consumer Kafka para un dominio en KLAP BYSF.
El listener es la puerta de entrada de mensajes: valida, delega al processor y confirma el ack.
Vive en `dominio/{nombre_dominio}/listener/`.

---

## Reglas del equipo

**DO:**
- Anotar la clase con `@Component @Slf4j @RequiredArgsConstructor`
- Usar `@Payload` y `@Header` explícitos en el método consumer
- Delegar toda la lógica de negocio al `XxxProcessor` — el listener solo orquesta
- Llamar `ack.acknowledge()` SOLO después de que el procesamiento fue exitoso
- Loggear siempre `idProceso` y `codigoSucursal` en cada operación de log
- Trackear el tiempo de procesamiento con `System.currentTimeMillis()`
- Implementar circuit breaker con `AtomicInteger consecutiveFailures` (threshold=10, reset=60s)
- Para errores deterministas: `enviarADlqManual()` + `ack.acknowledge()` sin re-throw
- Para errores de infraestructura: re-throw para que `KafkaConfig` maneje reintentos automáticos

**DON'T:**
- No poner lógica de negocio en el listener — solo validación superficial del mensaje y orquestación
- No hacer `ack.acknowledge()` antes de que el processor termine exitosamente
- No capturar `Exception` genérica y tragársela sin re-throw — rompe los reintentos automáticos
- No loggear datos sensibles (números de cuenta, RUT completo) en INFO o ERROR
- No usar `@KafkaListener` sin especificar `containerFactory` — debe apuntar al factory del dominio
- No omitir el tracking de tiempo — es el insumo para ajustar `max.poll.interval.ms`

---

## Skeleton de código

```java
package cl.klap.bysf.dominio.{nombre_dominio}.listener;

import cl.klap.bysf.dominio.{nombre_dominio}.model.{Xxx}InputDto;
import cl.klap.bysf.dominio.{nombre_dominio}.services.{Xxx}Processor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Listener Kafka para el dominio {NombreDominio}.
 * Responsabilidad única: recibir el mensaje, validarlo superficialmente,
 * delegar al processor y confirmar el ack. No contiene lógica de negocio.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class {Xxx}KafkaListener {

    private final {Xxx}Processor {xxx}Processor;
    private final KafkaTemplate<String, Object> dlqKafkaTemplate;

    // ── Circuit Breaker ───────────────────────────────────────────────────
    // Threshold: 10 fallas consecutivas → detiene el procesamiento 60s
    // para dar tiempo de recuperación a dependencias externas (DB, APIs)
    private static final int    CB_FAILURE_THRESHOLD = 10;
    private static final long   CB_RESET_TIMEOUT_MS  = 60_000L;
    private final AtomicInteger consecutiveFailures   = new AtomicInteger(0);
    private volatile long       cbOpenedAt            = 0L;

    // Tracking de tiempo para monitorear si se acerca a max.poll.interval.ms
    private final AtomicLong maxProcessingTimeMs = new AtomicLong(0L);

    /**
     * Punto de entrada del consumer. Recibe mensajes del topic de input del dominio,
     * los valida y los delega al {Xxx}Processor para procesamiento completo.
     * El ack se confirma solo si el procesamiento fue exitoso.
     *
     * @param mensaje  DTO deserializado del mensaje Kafka
     * @param idProceso identificador de correlación del proceso (header)
     * @param codigoSucursal código de la sucursal que originó la transacción (header)
     * @param ack      mecanismo de confirmación manual de offset
     */
    @KafkaListener(
        topics = "${kafka.topics.{dominio}.input}",
        groupId = "grupo-{dominio}-svbo",
        containerFactory = "{xxx}ListenerContainerFactory"
    )
    public void consumir(
        @Payload {Xxx}InputDto mensaje,
        @Header(value = "idProceso",      required = false) String idProceso,
        @Header(value = "codigoSucursal", required = false) String codigoSucursal,
        Acknowledgment ack
    ) {
        long inicio = System.currentTimeMillis();
        log.info("📨 Mensaje recibido | idProceso={} | codigoSucursal={} | tipo={}",
            idProceso, codigoSucursal, mensaje.getClass().getSimpleName());

        // ── Circuit Breaker: verificar si está abierto ────────────────────
        if (isCircuitBreakerOpen()) {
            log.warn("🔴 Circuit breaker abierto | idProceso={} | fallos={} | re-throw para reintento",
                idProceso, consecutiveFailures.get());
            throw new RuntimeException("Circuit breaker abierto — demasiados fallos consecutivos");
        }

        try {
            // Paso 1: Validación superficial del mensaje (no es lógica de negocio)
            validarMensaje(mensaje, idProceso);

            // Paso 2: Delegar procesamiento completo al Processor
            {xxx}Processor.procesar{Xxx}(mensaje, idProceso, codigoSucursal);

            // Paso 3: Confirmar offset SOLO si todo fue exitoso
            ack.acknowledge();
            consecutiveFailures.set(0); // reset circuit breaker

            long elapsed = System.currentTimeMillis() - inicio;
            actualizarMaxProcessingTime(elapsed);
            log.info("✅ Mensaje procesado exitosamente | idProceso={} | codigoSucursal={} | ms={}",
                idProceso, codigoSucursal, elapsed);

        } catch (IllegalArgumentException | IllegalStateException e) {
            // ── Error determinista: datos del mensaje inválidos ───────────
            // No tiene sentido reintentar — el mensaje nunca será válido.
            // Enviar a DLQ manualmente y confirmar el ack para liberar la partición.
            log.error("❌ Error determinista | idProceso={} | codigoSucursal={} | error={}",
                idProceso, codigoSucursal, e.getMessage());
            enviarADlqManual(mensaje, idProceso, e);
            ack.acknowledge(); // liberar la partición — este mensaje no se puede procesar
            consecutiveFailures.set(0);

        } catch (Exception e) {
            // ── Error de infraestructura: DB caída, API externa, timeout ──
            // Re-throw para que KafkaConfig aplique los 3 reintentos con 5s backoff.
            // Después del 3er intento, KafkaConfig lo envía al DLQ automáticamente.
            consecutiveFailures.incrementAndGet();
            log.error("⚠️ Error de infraestructura | idProceso={} | codigoSucursal={} | fallosConsecutivos={} | error={}",
                idProceso, codigoSucursal, consecutiveFailures.get(), e.getMessage());

            if (consecutiveFailures.get() >= CB_FAILURE_THRESHOLD) {
                cbOpenedAt = System.currentTimeMillis();
                log.error("🔴 Circuit breaker ABIERTO | umbral={} | resetEn={}ms",
                    CB_FAILURE_THRESHOLD, CB_RESET_TIMEOUT_MS);
            }
            throw e; // re-throw — KafkaConfig maneja los reintentos
        }
    }

    // ── Métodos privados de soporte ───────────────────────────────────────

    /**
     * Valida que el mensaje tenga los campos mínimos necesarios para ser procesado.
     * Solo valida presencia/formato básico — la lógica de negocio va en el Processor.
     *
     * @param mensaje   DTO a validar
     * @param idProceso identificador de correlación para logging
     * @throws IllegalArgumentException si el mensaje está incompleto o malformado
     */
    private void validarMensaje({Xxx}InputDto mensaje, String idProceso) {
        if (mensaje == null) {
            throw new IllegalArgumentException("Mensaje nulo recibido | idProceso=" + idProceso);
        }
        // Agregar validaciones de campos obligatorios específicos del dominio
        // Ejemplo: if (mensaje.getIdTransaccion() == null) throw new IllegalArgumentException(...)
    }

    /**
     * Envía el mensaje al DLQ de forma manual cuando se detecta un error determinista.
     * Se usa cuando el mensaje nunca podrá procesarse (datos inválidos, schema incorrecto).
     *
     * @param mensaje   mensaje original que no pudo procesarse
     * @param idProceso identificador de correlación
     * @param causa     excepción que originó el envío a DLQ
     */
    private void enviarADlqManual(Object mensaje, String idProceso, Exception causa) {
        try {
            log.warn("📤 Enviando a DLQ manual | idProceso={} | causa={}", idProceso, causa.getMessage());
            dlqKafkaTemplate.send(
                dlqKafkaTemplate.getDefaultTopic(),
                idProceso,
                mensaje
            ).get(); // sincrónico — necesitamos confirmar que llegó al DLQ
        } catch (Exception dlqEx) {
            log.error("❌ Fallo al enviar a DLQ | idProceso={} | error={}", idProceso, dlqEx.getMessage());
        }
    }

    /**
     * Verifica si el circuit breaker está abierto (demasiados fallos consecutivos).
     * Se resetea automáticamente después del timeout de 60s.
     *
     * @return true si el circuit breaker está abierto y se debe rechazar el mensaje
     */
    private boolean isCircuitBreakerOpen() {
        if (consecutiveFailures.get() < CB_FAILURE_THRESHOLD) return false;
        if (System.currentTimeMillis() - cbOpenedAt > CB_RESET_TIMEOUT_MS) {
            log.info("🔄 Circuit breaker RESETEADO después de {}ms", CB_RESET_TIMEOUT_MS);
            consecutiveFailures.set(0);
            return false;
        }
        return true;
    }

    /**
     * Actualiza el tiempo máximo de procesamiento observado.
     * Útil para monitorear si nos acercamos al límite de max.poll.interval.ms.
     *
     * @param elapsedMs tiempo transcurrido en el procesamiento del último mensaje
     */
    private void actualizarMaxProcessingTime(long elapsedMs) {
        long current = maxProcessingTimeMs.get();
        if (elapsedMs > current) {
            maxProcessingTimeMs.set(elapsedMs);
            log.debug("📊 Nuevo máximo de procesamiento: {}ms", elapsedMs);
        }
    }
}
```

---

## Ejemplo completo

```java
package cl.klap.bysf.dominio.liquidacion.listener;

import cl.klap.bysf.dominio.liquidacion.model.LiquidacionInputDto;
import cl.klap.bysf.dominio.liquidacion.services.LiquidacionProcessor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Listener Kafka para el dominio Liquidación SVBO.
 * Recibe solicitudes de liquidación, delega al LiquidacionProcessor
 * y confirma ack solo cuando el procesamiento completo fue exitoso.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LiquidacionKafkaListener {

    private final LiquidacionProcessor liquidacionProcessor;
    private final KafkaTemplate<String, Object> dlqKafkaTemplate;

    private static final int  CB_FAILURE_THRESHOLD = 10;
    private static final long CB_RESET_TIMEOUT_MS  = 60_000L;

    private final AtomicInteger consecutiveFailures = new AtomicInteger(0);
    private final AtomicLong    maxProcessingTimeMs = new AtomicLong(0L);
    private volatile long       cbOpenedAt          = 0L;

    /**
     * Consume mensajes del topic de entrada de liquidaciones SVBO.
     * Aplica circuit breaker, delega al processor y confirma ack en éxito.
     * Errores deterministas van a DLQ manual; errores de infraestructura
     * se re-lanzan para los reintentos automáticos de KafkaConfig.
     *
     * @param mensaje        DTO con los datos de la liquidación a procesar
     * @param idProceso      header de correlación del proceso
     * @param codigoSucursal header con el código de la sucursal originante
     * @param ack            mecanismo de confirmación manual de offset
     */
    @KafkaListener(
        topics = "${kafka.topics.liquidacion.input}",
        groupId = "grupo-liquidacion-svbo",
        containerFactory = "liquidacionListenerContainerFactory"
    )
    public void consumir(
        @Payload LiquidacionInputDto mensaje,
        @Header(value = "idProceso",      required = false) String idProceso,
        @Header(value = "codigoSucursal", required = false) String codigoSucursal,
        Acknowledgment ack
    ) {
        long inicio = System.currentTimeMillis();
        log.info("📨 Liquidación recibida | idProceso={} | codigoSucursal={}", idProceso, codigoSucursal);

        if (isCircuitBreakerOpen()) {
            log.warn("🔴 Circuit breaker abierto | idProceso={}", idProceso);
            throw new RuntimeException("Circuit breaker abierto");
        }

        try {
            validarMensaje(mensaje, idProceso);
            liquidacionProcessor.procesarLiquidacion(mensaje, idProceso, codigoSucursal);
            ack.acknowledge();
            consecutiveFailures.set(0);

            long elapsed = System.currentTimeMillis() - inicio;
            actualizarMaxProcessingTime(elapsed);
            log.info("✅ Liquidación procesada | idProceso={} | codigoSucursal={} | ms={}", idProceso, codigoSucursal, elapsed);

        } catch (IllegalArgumentException | IllegalStateException e) {
            log.error("❌ Error determinista en liquidación | idProceso={} | error={}", idProceso, e.getMessage());
            enviarADlqManual(mensaje, idProceso, e);
            ack.acknowledge();
            consecutiveFailures.set(0);

        } catch (Exception e) {
            consecutiveFailures.incrementAndGet();
            log.error("⚠️ Error infraestructura en liquidación | idProceso={} | fallos={} | error={}",
                idProceso, consecutiveFailures.get(), e.getMessage());
            if (consecutiveFailures.get() >= CB_FAILURE_THRESHOLD) {
                cbOpenedAt = System.currentTimeMillis();
                log.error("🔴 Circuit breaker ABIERTO | umbral={}", CB_FAILURE_THRESHOLD);
            }
            throw e;
        }
    }

    private void validarMensaje(LiquidacionInputDto mensaje, String idProceso) {
        if (mensaje == null) throw new IllegalArgumentException("Mensaje nulo | idProceso=" + idProceso);
        if (mensaje.getIdTransaccion() == null) throw new IllegalArgumentException("idTransaccion requerido | idProceso=" + idProceso);
        if (mensaje.getCodigoSucursal() == null) throw new IllegalArgumentException("codigoSucursal requerido | idProceso=" + idProceso);
    }

    private void enviarADlqManual(Object mensaje, String idProceso, Exception causa) {
        try {
            log.warn("📤 Enviando a DLQ | idProceso={} | causa={}", idProceso, causa.getMessage());
            dlqKafkaTemplate.send(dlqKafkaTemplate.getDefaultTopic(), idProceso, mensaje).get();
        } catch (Exception ex) {
            log.error("❌ Fallo DLQ manual | idProceso={} | error={}", idProceso, ex.getMessage());
        }
    }

    private boolean isCircuitBreakerOpen() {
        if (consecutiveFailures.get() < CB_FAILURE_THRESHOLD) return false;
        if (System.currentTimeMillis() - cbOpenedAt > CB_RESET_TIMEOUT_MS) {
            consecutiveFailures.set(0);
            return false;
        }
        return true;
    }

    private void actualizarMaxProcessingTime(long elapsedMs) {
        long current = maxProcessingTimeMs.get();
        if (elapsedMs > current) maxProcessingTimeMs.set(elapsedMs);
    }
}
```

---

## Anti-patrones a evitar

- `ack.acknowledge()` al inicio del método antes de delegar — si falla el processor, el mensaje se pierde
- Capturar `Exception` y no re-throw — los reintentos automáticos de `KafkaConfig` nunca se ejecutan
- Lógica de negocio dentro del listener — el listener es orquestador, no domain service
- Omitir el circuit breaker — sin él, una dependencia caída puede provocar un storm de reintentos
- Loggear RUT o número de cuenta completo en INFO/ERROR — datos sensibles solo en DEBUG con máscara
- No especificar `containerFactory` en `@KafkaListener` — Spring usa un factory genérico sin DLQ ni AckMode correcto
- Envío asincrónico al DLQ manual (sin `.get()`) — si el DLQ falla, no lo sabemos y el mensaje se pierde silenciosamente
