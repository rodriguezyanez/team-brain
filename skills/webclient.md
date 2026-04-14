# Skill: WebClient (Cliente HTTP Externo)

## Cuándo usar este skill

Cuando necesites llamar a una API externa (REST) desde un servicio KLAP BYSF.
WebFlux se usa **solo como cliente HTTP** — el servidor sigue siendo Spring MVC (spring-boot-starter-web).
No aplica para comunicación interna entre microservicios vía Kafka.

---

## Reglas del equipo

**DO:**
- Definir timeouts explícitos: `CONNECT_TIMEOUT` + `responseTimeout` + `ReadTimeoutHandler` + `WriteTimeoutHandler`
- Usar `Retry.fixedDelay(maxAttempts, backoffDelay)` para reintentos
- Llamar con `.block()` — dominios financieros requieren flujo sincrónico predecible
- Mapear `4xx` y `5xx` a `XxxClientException` con `statusCode` + `responseBody`
- Inyectar `WebClient` ya construido en `XxxClient` (no crear instancias dentro de métodos)
- Loguear el error con `statusCode` y primeros N chars del body antes de lanzar la excepción

**DON'T:**
- No reintentar `IllegalArgumentException` — error de datos, es determinista y no cambia con reintentos
- No usar reactive chain completo (`.flatMap().subscribe()`) — siempre terminar en `.block()`
- No quitar `spring-boot-starter-web` al agregar `spring-webflux` — ambas deben coexistir
- No hardcodear la base URL en `XxxClient` — configurarla en `XxxClientConfig` via `@Value`
- No ignorar errores de timeout — deben lanzar `XxxClientException`

---

## Dependencia Gradle

```groovy
// build.gradle — agregar junto a spring-boot-starter-web, NO en lugar de
implementation 'org.springframework.boot:spring-boot-starter-webflux'
```

**Importante:** `spring-boot-starter-web` y `spring-boot-starter-webflux` deben coexistir.
Spring Boot detecta ambas y mantiene el servidor Tomcat (MVC). WebFlux se usa solo para el `WebClient`.

---

## Skeleton de código

### Constantes de configuración en `application.yml`

```yaml
clients:
  xxx-api:
    base-url: https://api.externa.cl
    connect-timeout-ms: 3000
    response-timeout-ms: 10000
    retry-max-attempts: 3
    retry-backoff-ms: 500
```

---

## Ejemplo completo

### `XxxClientConfig.java` (en `services/client/`)

```java
package cl.klap.bysf.svbo.liquidacion.services.client;

import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * Configuración del WebClient para consumir la API externa XxxApi.
 * Define timeouts en tres niveles: TCP connect, respuesta HTTP y read/write de socket.
 * Todos los valores se externalizan en application.yml para ser sobreescritos por ambiente.
 */
@Configuration
public class XxxClientConfig {

    @Value("${clients.xxx-api.base-url}")
    private String baseUrl;

    @Value("${clients.xxx-api.connect-timeout-ms:3000}")
    private int connectTimeoutMs;

    @Value("${clients.xxx-api.response-timeout-ms:10000}")
    private int responseTimeoutMs;

    /**
     * Crea el bean {@link WebClient} configurado con timeouts explícitos para la API externa.
     * Se define un único bean por cliente externo para reutilizar el pool de conexiones de Netty.
     *
     * @return instancia de WebClient lista para inyectar en {@link XxxClient}
     */
    @Bean
    public WebClient xxxWebClient() {
        // HttpClient de Netty con timeouts a nivel TCP y socket
        HttpClient httpClient = HttpClient.create()
                // Timeout de establecimiento de conexión TCP
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, connectTimeoutMs)
                // Timeout total desde que se envía el request hasta que llega la primera respuesta
                .responseTimeout(Duration.ofMillis(responseTimeoutMs))
                .doOnConnected(conn -> conn
                        // Timeout de lectura de bytes del socket (por chunk)
                        .addHandlerLast(new ReadTimeoutHandler(responseTimeoutMs, TimeUnit.MILLISECONDS))
                        // Timeout de escritura de bytes al socket
                        .addHandlerLast(new WriteTimeoutHandler(responseTimeoutMs, TimeUnit.MILLISECONDS))
                );

        return WebClient.builder()
                .baseUrl(baseUrl)
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                // Aumentar límite del buffer si la API devuelve respuestas grandes (default: 256KB)
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(1024 * 1024))
                .build();
    }
}
```

### `XxxClient.java` (en `services/client/`)

```java
package cl.klap.bysf.svbo.liquidacion.services.client;

import cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions.XxxClientException;
import cl.klap.bysf.svbo.liquidacion.services.client.dto.XxxRequestDto;
import cl.klap.bysf.svbo.liquidacion.services.client.dto.XxxResponseDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientRequestException;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;

import java.time.Duration;

/**
 * Cliente HTTP para la API externa XxxApi.
 * Encapsula reintentos, manejo de errores HTTP y mapeo de excepciones del dominio.
 * Todas las llamadas son sincrónicas (.block()) para mantener trazabilidad en dominios financieros.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class XxxClient {

    // Bean definido en XxxClientConfig — inyectado por nombre para distinguir de otros WebClients
    private final WebClient xxxWebClient;

    @Value("${clients.xxx-api.retry-max-attempts:3}")
    private long retryMaxAttempts;

    @Value("${clients.xxx-api.retry-backoff-ms:500}")
    private long retryBackoffMs;

    /**
     * Envía una solicitud de liquidación a la API externa y retorna su respuesta.
     * Reintenta automáticamente en errores transitorios (5xx, timeout de red).
     * No reintenta errores de datos ({@link IllegalArgumentException}) porque son deterministas.
     *
     * @param request datos del request a enviar
     * @return respuesta de la API externa mapeada a {@link XxxResponseDto}
     * @throws XxxClientException si la API responde con 4xx o 5xx, o si se agota el timeout
     */
    public XxxResponseDto enviarLiquidacion(XxxRequestDto request) {
        log.info("Llamando a XxxApi para liquidacion id={}", request.getId());

        return xxxWebClient.post()
                .uri("/v1/liquidaciones")
                .bodyValue(request)
                .retrieve()
                // Mapeo de errores 4xx — errores de negocio/datos en el request
                .onStatus(HttpStatusCode::is4xxClientError, clientResponse ->
                        clientResponse.bodyToMono(String.class)
                                .defaultIfEmpty("")
                                .flatMap(body -> {
                                    log.error("XxxApi respondio 4xx: status={}, body={}",
                                            clientResponse.statusCode().value(),
                                            body.length() > 500 ? body.substring(0, 500) : body);
                                    return Mono.error(new XxxClientException(
                                            "Error 4xx de XxxApi",
                                            clientResponse.statusCode().value(),
                                            body));
                                })
                )
                // Mapeo de errores 5xx — errores de infraestructura de la API externa
                .onStatus(HttpStatusCode::is5xxServerError, clientResponse ->
                        clientResponse.bodyToMono(String.class)
                                .defaultIfEmpty("")
                                .flatMap(body -> {
                                    log.error("XxxApi respondio 5xx: status={}, body={}",
                                            clientResponse.statusCode().value(),
                                            body.length() > 500 ? body.substring(0, 500) : body);
                                    return Mono.error(new XxxClientException(
                                            "Error 5xx de XxxApi",
                                            clientResponse.statusCode().value(),
                                            body));
                                })
                )
                .bodyToMono(XxxResponseDto.class)
                // Reintentos con backoff fijo — solo para errores transitorios
                // IllegalArgumentException NO se reintenta: error de datos, determinista
                .retryWhen(Retry.fixedDelay(retryMaxAttempts, Duration.ofMillis(retryBackoffMs))
                        .filter(throwable -> !(throwable instanceof IllegalArgumentException))
                        .doBeforeRetry(signal ->
                                log.warn("Reintentando llamada a XxxApi, intento={}, causa={}",
                                        signal.totalRetries() + 1,
                                        signal.failure().getMessage()))
                )
                // Dominio financiero: flujo sincrónico obligatorio para trazabilidad y manejo de errores predecible
                .block();
    }

    /**
     * Consulta el estado de una liquidación previamente enviada.
     *
     * @param liquidacionId identificador de la liquidación a consultar
     * @return estado actual de la liquidación en el sistema externo
     * @throws XxxClientException si la API externa responde con error o hay timeout
     */
    public XxxResponseDto consultarEstado(String liquidacionId) {
        log.info("Consultando estado en XxxApi para liquidacionId={}", liquidacionId);

        return xxxWebClient.get()
                .uri("/v1/liquidaciones/{id}", liquidacionId)
                .retrieve()
                .onStatus(HttpStatusCode::is4xxClientError, clientResponse ->
                        clientResponse.bodyToMono(String.class)
                                .defaultIfEmpty("")
                                .flatMap(body -> Mono.error(new XxxClientException(
                                        "Error consultando estado en XxxApi",
                                        clientResponse.statusCode().value(),
                                        body)))
                )
                .onStatus(HttpStatusCode::is5xxServerError, clientResponse ->
                        clientResponse.bodyToMono(String.class)
                                .defaultIfEmpty("")
                                .flatMap(body -> Mono.error(new XxxClientException(
                                        "Error de servidor consultando estado en XxxApi",
                                        clientResponse.statusCode().value(),
                                        body)))
                )
                .bodyToMono(XxxResponseDto.class)
                .retryWhen(Retry.fixedDelay(retryMaxAttempts, Duration.ofMillis(retryBackoffMs))
                        .filter(throwable -> !(throwable instanceof IllegalArgumentException))
                )
                .block();
    }
}
```

---

## Anti-patrones a evitar

- **Sin timeouts:** `WebClient.create(baseUrl)` sin configurar `HttpClient` — el thread puede quedar bloqueado indefinitely
- **Reactive chain completo:** `.flatMap(...).subscribe(...)` en vez de `.block()` — rompe la trazabilidad en dominios financieros
- **Reintentar 4xx:** los errores 4xx son deterministas (payload inválido, not found) — reintentarlos es inútil y genera carga innecesaria
- **Reintentar `IllegalArgumentException`:** error de validación de datos — mismo problema que 4xx
- **URL hardcodeada en el client:** `WebClient.create("https://api.externa.cl")` en el método — usar `@Value` + config
- **Ignorar el body del error:** lanzar excepción sin incluir el `responseBody` dificulta el debug en producción
- **Reemplazar spring-boot-starter-web:** ambas dependencias deben coexistir; eliminar MVC convierte el servidor a reactivo
