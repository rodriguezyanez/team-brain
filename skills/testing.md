# Skill: Testing — KLAP BYSF

> Template de tests unitarios para servicios, repositorios y clientes HTTP.

---

## Framework

- JUnit 5 + `@ExtendWith(MockitoExtension.class)`
- Mockito (mocks, captors, verificaciones)
- AssertJ (`assertThat(...)`)
- MockWebServer (OkHttp) para tests de `XxxClient`
- JaCoCo: **95% cobertura mínima** — el build falla si no se alcanza

---

## Estructura de clase de test

```java
@ExtendWith(MockitoExtension.class)
class XxxServiceImplTest {

    @Mock
    private XxxRepository xxxRepository;

    @Mock
    private XxxClient xxxClient;

    @InjectMocks
    private XxxServiceImpl xxxService;

    @Captor
    private ArgumentCaptor<XxxEntity> xxxCaptor;
}
```

- `@Mock` — una anotación por dependencia inyectada en el sujeto
- `@InjectMocks` — la clase concreta bajo test (impl, no interfaz)
- `@Captor` — para capturar argumentos y verificar su contenido

---

## Patrón Arrange-Act-Assert (AAA)

```java
@Test
void testProcesarLiquidacionExitoso() {
    // Arrange
    LiquidacionRequest request = buildRequest();
    LiquidacionEntity entity = buildEntity();
    when(xxxRepository.findById(1L)).thenReturn(Optional.of(entity));
    when(xxxClient.consultar(any())).thenReturn(buildResponse());

    // Act
    LiquidacionResult result = xxxService.procesar(request);

    // Assert
    assertThat(result).isNotNull();
    assertThat(result.getEstado()).isEqualTo(EstadoLiquidacion.PROCESADO);
    verify(xxxRepository, times(1)).findById(1L);
    verify(xxxClient, times(1)).consultar(any());
}
```

---

## Naming de tests

| Escenario | Nombre del método |
|-----------|------------------|
| Flujo feliz | `testProcesarLiquidacionExitoso()` |
| Error de negocio | `testProcesarLiquidacionConError()` |
| Validación de entrada | `testProcesarLiquidacionConValidacion()` |
| Not found | `testBuscarLiquidacionNoEncontrada()` |
| Timeout / retriable | `testConsultarClienteConTimeout()` |

---

## Template: XxxServiceImpl Test

```java
/**
 * Tests unitarios para XxxServiceImpl.
 * Verifica el comportamiento de negocio aislando todas las dependencias externas.
 */
@ExtendWith(MockitoExtension.class)
class XxxServiceImplTest {

    @Mock
    private XxxRepository xxxRepository;

    @InjectMocks
    private XxxServiceImpl xxxService;

    @Captor
    private ArgumentCaptor<XxxEntity> entityCaptor;

    /**
     * Verifica que el procesamiento exitoso persiste la entidad con estado correcto.
     */
    @Test
    void testProcesarExitoso() {
        // Arrange
        Long id = 1L;
        XxxEntity entity = XxxEntity.builder().id(id).estado(Estado.PENDIENTE).build();
        when(xxxRepository.findById(id)).thenReturn(Optional.of(entity));
        doNothing().when(xxxRepository).save(any());

        // Act
        XxxResult result = xxxService.procesar(id);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(id);
        verify(xxxRepository).save(entityCaptor.capture());
        assertThat(entityCaptor.getValue().getEstado()).isEqualTo(Estado.PROCESADO);
    }

    /**
     * Verifica que se lanza XxxNotFoundException cuando la entidad no existe.
     */
    @Test
    void testProcesarConEntidadNoEncontrada() {
        // Arrange
        when(xxxRepository.findById(anyLong())).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> xxxService.procesar(99L))
                .isInstanceOf(XxxNotFoundException.class)
                .hasMessageContaining("99");

        verify(xxxRepository, never()).save(any());
    }

    /**
     * Verifica que un error de repositorio se propaga correctamente.
     */
    @Test
    void testProcesarConErrorRepositorio() {
        // Arrange
        when(xxxRepository.findById(anyLong()))
                .thenThrow(new DataAccessException("DB error") {});

        // Act & Assert
        assertThatThrownBy(() -> xxxService.procesar(1L))
                .isInstanceOf(DataAccessException.class);
    }
}
```

---

## Template: XxxRepository Test (JdbcTemplate mockeado)

```java
/**
 * Tests unitarios para XxxRepository.
 * Mockea JdbcTemplate para aislar la lógica SQL del repositorio.
 */
@ExtendWith(MockitoExtension.class)
class XxxRepositoryTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private XxxRepository xxxRepository;

    /**
     * Verifica que findById construye el query correcto y mapea el resultado.
     */
    @Test
    void testFindByIdExitoso() {
        // Arrange
        Long id = 42L;
        XxxEntity expected = XxxEntity.builder().id(id).build();
        when(jdbcTemplate.queryForObject(anyString(), any(RowMapper.class), eq(id)))
                .thenReturn(expected);

        // Act
        Optional<XxxEntity> result = xxxRepository.findById(id);

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().getId()).isEqualTo(id);
    }

    /**
     * Verifica que findById retorna Optional.empty() cuando no existe el registro.
     */
    @Test
    void testFindByIdNoEncontrado() {
        // Arrange
        when(jdbcTemplate.queryForObject(anyString(), any(RowMapper.class), anyLong()))
                .thenThrow(new EmptyResultDataAccessException(1));

        // Act
        Optional<XxxEntity> result = xxxRepository.findById(99L);

        // Assert
        assertThat(result).isEmpty();
    }
}
```

---

## Template: XxxClient Test (MockWebServer)

```java
/**
 * Tests unitarios para XxxClient.
 * Usa MockWebServer para simular respuestas HTTP sin levantar Spring context.
 */
class XxxClientTest {

    private MockWebServer mockWebServer;
    private XxxClient xxxClient;

    /**
     * Levanta el servidor mock y configura WebClient apuntando a él.
     */
    @BeforeEach
    void setUp() throws IOException {
        mockWebServer = new MockWebServer();
        mockWebServer.start();

        WebClient webClient = WebClient.builder()
                .baseUrl(mockWebServer.url("/").toString())
                .build();

        xxxClient = new XxxClient(webClient);
    }

    /**
     * Cierra el servidor mock al finalizar cada test.
     */
    @AfterEach
    void tearDown() throws IOException {
        mockWebServer.shutdown();
    }

    /**
     * Verifica que el cliente parsea correctamente una respuesta 200 OK.
     */
    @Test
    void testConsultarExitoso() throws InterruptedException {
        // Arrange
        String responseBody = """
                {"id": 1, "estado": "ACTIVO"}
                """;
        mockWebServer.enqueue(new MockResponse()
                .setBody(responseBody)
                .addHeader("Content-Type", "application/json")
                .setResponseCode(200));

        // Act
        XxxResponse result = xxxClient.consultar(1L);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(1L);

        RecordedRequest request = mockWebServer.takeRequest();
        assertThat(request.getMethod()).isEqualTo("GET");
        assertThat(request.getPath()).isEqualTo("/xxx/1");
    }

    /**
     * Verifica que el cliente lanza XxxClientException ante respuesta 4xx.
     */
    @Test
    void testConsultarCon404() {
        // Arrange
        mockWebServer.enqueue(new MockResponse().setResponseCode(404));

        // Act & Assert
        assertThatThrownBy(() -> xxxClient.consultar(99L))
                .isInstanceOf(XxxClientException.class);
    }

    /**
     * Verifica que el cliente lanza XxxClientException ante respuesta 5xx.
     */
    @Test
    void testConsultarCon500() {
        // Arrange
        mockWebServer.enqueue(new MockResponse().setResponseCode(500).setBody("Internal Server Error"));

        // Act & Assert
        assertThatThrownBy(() -> xxxClient.consultar(1L))
                .isInstanceOf(XxxClientException.class);
    }
}
```

---

## Dependencias Gradle

```gradle
testImplementation 'org.junit.jupiter:junit-jupiter:5.11.0'
testImplementation 'org.mockito:mockito-junit-jupiter:5.12.0'
testImplementation 'org.assertj:assertj-core:3.26.0'
testImplementation 'com.squareup.okhttp3:mockwebserver:4.12.0'
testImplementation 'com.squareup.okhttp3:okhttp:4.12.0'
```

JaCoCo en `build.gradle`:

```gradle
jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = 0.95
            }
        }
    }
}

check.dependsOn jacocoTestCoverageVerification
```

---

## DON'T

- NO usar `@SpringBootTest` para unit tests — es un integration test, levanta el contexto completo y es lento
- NO mockear `JdbcTemplate` con mocks complejos para validar SQL — usar H2 en integration tests si se necesita validar queries reales
- NO usar `Mockito.reset()` entre tests — cada test debe ser independiente, usar `@BeforeEach` para setup limpio
- NO ignorar el `verify(...)` — siempre verificar que las interacciones esperadas ocurrieron
- NO escribir asserts en el bloque Arrange ni setup en el bloque Assert

---

*Skill: testing · KLAP BYSF · Stack: Java 21 / Spring Boot 3.5.11 / JUnit 5 / Mockito / AssertJ / MockWebServer*
