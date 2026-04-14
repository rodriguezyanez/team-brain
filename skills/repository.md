# Skill: Repository (JdbcTemplate)

## Cuándo usar este skill

Cuando necesites implementar acceso a datos con JdbcTemplate en un dominio de KLAP BYSF.
Aplica a cualquier `XxxRepository` que lea o escriba en PostgreSQL Aurora.

---

## Reglas del equipo

**DO:**
- Usar `ConstantsQuery.XXX` para **todas** las queries — nunca SQL inline en el repository
- Inyectar `JdbcTemplate` por constructor via `@RequiredArgsConstructor` (Lombok)
- Paginación cursor-based para tablas con más de 500 registros: `WHERE id > :lastId ORDER BY id LIMIT :pageSize`
- Colocar `RowMapper`s en el paquete `mapper/` si la entidad tiene 20+ columnas o el mapper se reutiliza en múltiples métodos
- Usar cache con TTL explícito para datos de configuración leídos frecuentemente
- Envolver toda `DataAccessException` en `XxxPersistenceException`
- Crear `AuditoriaXxxRepository` para trazabilidad de operaciones de escritura

**DON'T:**
- No usar JPA / Hibernate bajo ninguna circunstancia
- No hardcodear SQL en el cuerpo del repository
- No usar `OFFSET/LIMIT` en tablas grandes (degrada con el tiempo)
- No usar cache sin TTL (riesgo de datos stale indefinido)
- No dejar escapar `DataAccessException` sin envolver

---

## Naming de métodos

| Operación | Nombre |
|-----------|--------|
| Buscar por PK | `findById(Long id)` |
| Buscar todos | `findAll()` |
| Insertar | `insert(Xxx entity)` |
| Actualizar | `update(Xxx entity)` |
| Paginación cursor | `findByCursorAfter(Long lastId, int pageSize)` |
| Buscar por campo | `findByNombreCampo(String valor)` |

---

## Skeleton de código

### `ConstantsQuery.java`

```java
package cl.klap.bysf.{modulo}.{aplicacion}.dominio.{nombre_dominio};

/**
 * Constantes de queries SQL para el dominio {NombreDominio}.
 * Centraliza todas las sentencias SQL para facilitar mantenimiento y revisión.
 */
public final class ConstantsQuery {

    private ConstantsQuery() {
        // Utility class — no instanciar
    }

    // -------------------------------------------------------------------------
    // SELECT
    // -------------------------------------------------------------------------

    /** Busca un registro por su clave primaria. */
    public static final String FIND_BY_ID =
            "SELECT id, columna_a, columna_b, created_at, updated_at " +
            "FROM esquema.tabla " +
            "WHERE id = :id";

    /** Recupera todos los registros activos. */
    public static final String FIND_ALL =
            "SELECT id, columna_a, columna_b, created_at, updated_at " +
            "FROM esquema.tabla " +
            "WHERE activo = true " +
            "ORDER BY id";

    /**
     * Paginación cursor-based: trae la siguiente página desde lastId.
     * Uso: {@code findByCursorAfter(lastId, pageSize)}.
     */
    public static final String FIND_BY_CURSOR_AFTER =
            "SELECT id, columna_a, columna_b, created_at, updated_at " +
            "FROM esquema.tabla " +
            "WHERE id > :lastId " +
            "ORDER BY id " +
            "LIMIT :pageSize";

    // -------------------------------------------------------------------------
    // INSERT / UPDATE
    // -------------------------------------------------------------------------

    /** Inserta un nuevo registro. Retorna el id generado. */
    public static final String INSERT =
            "INSERT INTO esquema.tabla (columna_a, columna_b, created_at) " +
            "VALUES (:columnaA, :columnaB, NOW()) " +
            "RETURNING id";

    /** Actualiza los campos modificables de un registro existente. */
    public static final String UPDATE =
            "UPDATE esquema.tabla " +
            "SET columna_a = :columnaA, columna_b = :columnaB, updated_at = NOW() " +
            "WHERE id = :id";

    // -------------------------------------------------------------------------
    // AUDITORÍA
    // -------------------------------------------------------------------------

    /** Registra una entrada de auditoría para trazabilidad. */
    public static final String INSERT_AUDITORIA =
            "INSERT INTO esquema.auditoria_tabla (tabla_id, operacion, payload, created_at) " +
            "VALUES (:tablaId, :operacion, :payload::jsonb, NOW())";
}
```

---

## Ejemplo completo

### `LiquidacionRepository.java`

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion;

import cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions.LiquidacionPersistenceException;
import cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.mapper.LiquidacionRowMapper;
import cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.model.Liquidacion;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository de acceso a datos para la entidad Liquidacion.
 * Todas las queries se resuelven via {@link LiquidacionConstantsQuery} — nunca SQL inline.
 */
@Repository
@RequiredArgsConstructor
@Slf4j
public class LiquidacionRepository {

    // NamedParameterJdbcTemplate permite usar :parametro en lugar de ? — más legible y seguro
    private final NamedParameterJdbcTemplate jdbcTemplate;
    private final LiquidacionRowMapper rowMapper;

    /**
     * Busca una liquidación por su identificador único.
     *
     * @param id identificador de la liquidación
     * @return {@link Optional} con la liquidación si existe, vacío si no
     * @throws LiquidacionPersistenceException si ocurre un error de acceso a la base de datos
     */
    public Optional<Liquidacion> findById(Long id) {
        log.debug("Buscando liquidacion con id={}", id);
        try {
            var params = new MapSqlParameterSource("id", id);
            var result = jdbcTemplate.queryForObject(
                    LiquidacionConstantsQuery.FIND_BY_ID, params, rowMapper);
            return Optional.ofNullable(result);
        } catch (EmptyResultDataAccessException e) {
            // Resultado vacío no es un error — retornamos Optional.empty()
            return Optional.empty();
        } catch (DataAccessException e) {
            log.error("Error al buscar liquidacion id={}", id, e);
            throw new LiquidacionPersistenceException("Error al buscar liquidacion id=" + id, e);
        }
    }

    /**
     * Recupera una página de liquidaciones usando cursor-based pagination.
     * Más eficiente que OFFSET en tablas grandes porque usa el índice de id directamente.
     *
     * @param lastId   id del último elemento de la página anterior (0 para la primera página)
     * @param pageSize cantidad máxima de registros a retornar
     * @return lista de liquidaciones ordenadas por id ascendente
     * @throws LiquidacionPersistenceException si ocurre un error de acceso a la base de datos
     */
    public List<Liquidacion> findByCursorAfter(Long lastId, int pageSize) {
        log.debug("Paginando liquidaciones desde lastId={}, pageSize={}", lastId, pageSize);
        try {
            var params = new MapSqlParameterSource()
                    .addValue("lastId", lastId)
                    .addValue("pageSize", pageSize);
            return jdbcTemplate.query(
                    LiquidacionConstantsQuery.FIND_BY_CURSOR_AFTER, params, rowMapper);
        } catch (DataAccessException e) {
            log.error("Error al paginar liquidaciones desde lastId={}", lastId, e);
            throw new LiquidacionPersistenceException("Error al paginar liquidaciones", e);
        }
    }

    /**
     * Inserta una nueva liquidación en la base de datos.
     * Retorna el id generado por la secuencia de PostgreSQL.
     *
     * @param liquidacion entidad a persistir (sin id)
     * @return id generado por la base de datos
     * @throws LiquidacionPersistenceException si ocurre un error al insertar
     */
    public Long insert(Liquidacion liquidacion) {
        log.info("Insertando nueva liquidacion para periodo={}", liquidacion.getPeriodo());
        try {
            var params = new MapSqlParameterSource()
                    .addValue("columnaA", liquidacion.getColumnaA())
                    .addValue("columnaB", liquidacion.getColumnaB());
            return jdbcTemplate.queryForObject(
                    LiquidacionConstantsQuery.INSERT, params, Long.class);
        } catch (DataAccessException e) {
            log.error("Error al insertar liquidacion={}", liquidacion, e);
            throw new LiquidacionPersistenceException("Error al insertar liquidacion", e);
        }
    }

    /**
     * Actualiza los campos modificables de una liquidación existente.
     *
     * @param liquidacion entidad con los nuevos valores (debe tener id)
     * @throws LiquidacionPersistenceException si ocurre un error al actualizar
     */
    public void update(Liquidacion liquidacion) {
        log.info("Actualizando liquidacion id={}", liquidacion.getId());
        try {
            var params = new MapSqlParameterSource()
                    .addValue("id", liquidacion.getId())
                    .addValue("columnaA", liquidacion.getColumnaA())
                    .addValue("columnaB", liquidacion.getColumnaB());
            jdbcTemplate.update(LiquidacionConstantsQuery.UPDATE, params);
        } catch (DataAccessException e) {
            log.error("Error al actualizar liquidacion id={}", liquidacion.getId(), e);
            throw new LiquidacionPersistenceException(
                    "Error al actualizar liquidacion id=" + liquidacion.getId(), e);
        }
    }
}
```

### `LiquidacionRowMapper.java` (en `mapper/`)

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.mapper;

import cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.model.Liquidacion;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Mapea una fila de la tabla {@code esquema.tabla} a la entidad {@link Liquidacion}.
 * Extraído a clase propia porque la entidad tiene más de 20 columnas y el mapper
 * se reutiliza en múltiples queries del repository.
 */
@Component
public class LiquidacionRowMapper implements RowMapper<Liquidacion> {

    /**
     * Convierte una fila del ResultSet en una instancia de {@link Liquidacion}.
     *
     * @param rs     resultado de la query posicionado en la fila actual
     * @param rowNum número de fila (usado internamente por JdbcTemplate)
     * @return entidad Liquidacion poblada con los datos de la fila
     * @throws SQLException si ocurre un error al leer una columna del ResultSet
     */
    @Override
    public Liquidacion mapRow(ResultSet rs, int rowNum) throws SQLException {
        return Liquidacion.builder()
                .id(rs.getLong("id"))
                .columnaA(rs.getString("columna_a"))
                .columnaB(rs.getString("columna_b"))
                .createdAt(rs.getTimestamp("created_at").toLocalDateTime())
                .updatedAt(rs.getTimestamp("updated_at") != null
                        ? rs.getTimestamp("updated_at").toLocalDateTime()
                        : null)
                .build();
    }
}
```

### `AuditoriaLiquidacionRepository.java`

```java
package cl.klap.bysf.svbo.liquidacion.dominio.liquidacion;

import cl.klap.bysf.svbo.liquidacion.dominio.liquidacion.exceptions.LiquidacionPersistenceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * Repository de auditoría para trazabilidad de todas las operaciones sobre Liquidacion.
 * Registra quién hizo qué y cuándo, con el payload completo en JSON.
 */
@Repository
@RequiredArgsConstructor
@Slf4j
public class AuditoriaLiquidacionRepository {

    private final NamedParameterJdbcTemplate jdbcTemplate;

    /**
     * Registra una entrada de auditoría para una operación sobre la entidad Liquidacion.
     *
     * @param tablaId   id del registro afectado
     * @param operacion tipo de operación: INSERT, UPDATE, DELETE
     * @param payload   representación JSON del estado de la entidad post-operación
     * @throws LiquidacionPersistenceException si falla el registro de auditoría
     */
    public void registrar(Long tablaId, String operacion, String payload) {
        log.debug("Registrando auditoria: tablaId={}, operacion={}", tablaId, operacion);
        try {
            var params = new MapSqlParameterSource()
                    .addValue("tablaId", tablaId)
                    .addValue("operacion", operacion)
                    .addValue("payload", payload);
            jdbcTemplate.update(LiquidacionConstantsQuery.INSERT_AUDITORIA, params);
        } catch (DataAccessException e) {
            log.error("Error al registrar auditoria tablaId={}, operacion={}", tablaId, operacion, e);
            throw new LiquidacionPersistenceException("Error al registrar auditoria", e);
        }
    }
}
```

---

## Anti-patrones a evitar

- **SQL hardcodeado:** `jdbcTemplate.query("SELECT * FROM tabla WHERE id = ?", ...)` — mover a `ConstantsQuery`
- **JPA/Hibernate:** ninguna dependencia `spring-boot-starter-data-jpa` en este proyecto
- **OFFSET en tablas grandes:** `LIMIT 100 OFFSET 5000` se vuelve lento; usar cursor-based
- **Cache sin TTL:** `@Cacheable` sin `@CacheEvict` o TTL configurado en `application.yml`
- **DataAccessException sin envolver:** dejar que suba al service layer con tipo genérico de Spring
- **RowMapper anónimo inline:** si la entidad tiene 20+ columnas, extraer a clase en `mapper/`
