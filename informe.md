# Informe Técnico — LAB-01: Bitácoras y auditoría del dato en PostgreSQL

* **Estudiante:** Ana Maribel Felipe Rodriguez
* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos
* **Base de datos:** `comercial` (Comercializadora Norte S.A. de C.V.)

---

## 1. Despliegue y situación inicial

El laboratorio se ejecutó sobre una instancia nativa de **PostgreSQL 16** en **Windows**, administrada mediante la sesión local de superusuario (`postgres`) en SQL Shell (`psql`) y sesiones cliente por red (`127.0.0.1`) mediante cadenas de conexión `postgresql://...`[cite: 4].

Al revisar los parámetros de registro iniciales en `pg_settings`, la configuración por defecto impedía responder las preguntas de Dirección ante el incidente reportado por facturación (alteración del RFC de la clienta María García, `id = 3`):
* `log_connections = off` y `log_disconnections = off`: no quedaba rastro de quién abría o cerraba sesión[cite: 4].
* `log_statement = none`: no se registraba ninguna sentencia SQL ejecutada[cite: 4].
* `log_line_prefix = '%m [%p] '`: únicamente incluía la fecha/hora y el PID del proceso, omitiendo el usuario (`%u`), la base de datos (`%d`), la aplicación (`%a`) y la IP del cliente (`%h`)[cite: 4].

En la Actividad 3 se reprodujo el cambio del RFC mediante `app_ventas` y se comprobó que no existía evidencia ni en la bitácora ni en tablas de auditoría, demostrando que el control de acceso (Unidad II) restringe quién *puede* operar, pero no genera por sí mismo evidencia de quién *ejecutó* una acción legítima o abusiva[cite: 4].

---

## 2. Configuración aplicada

Para que el motor administrara sus propios archivos de bitácora de forma uniforme y consultable desde SQL, se creó el esquema restringido `dba` (`REVOKE ALL ON SCHEMA dba FROM PUBLIC`) y la vista `dba.bitacora` apoyada en `pg_read_file(pg_current_logfile())`[cite: 4].

Los parámetros modificados mediante `ALTER SYSTEM` (persistidos en `postgresql.auto.conf`) fueron:

| Parámetro | Valor aplicado | Mecanismo de aplicación | Justificación |
| :--- | :--- | :--- | :--- |
| `logging_collector` | `on` | **Reinicio del servicio** | Captura `stderr` en archivos administrados por PostgreSQL dentro de `log_directory`, habilitando `pg_current_logfile()` y `dba.bitacora`[cite: 4]. |
| `log_connections` | `on` | **Recarga (`pg_reload_conf()`)** | Registra cada intento de conexión, autenticación y autorización (exitosa o fallida)[cite: 4]. |
| `log_disconnections` | `on` | **Recarga (`pg_reload_conf()`)** | Registra el cierre de cada sesión, su duración y el `application_name` final[cite: 4]. |
| `log_line_prefix` | `'%m [%p] user=%u db=%d app=%a client=%h '` | **Recarga (`pg_reload_conf()`)** | Incorpora fecha/hora con milisegundos, PID, usuario, base de datos, aplicación e IP del cliente para atribuir cada línea[cite: 4]. |
| `log_statement` | `'ddl'` → `'mod'` | **Recarga (`pg_reload_conf()`)** | En `'ddl'` registra cambios de estructura y privilegios; en `'mod'` añade `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` y `COPY FROM` sin saturar la bitácora con `SELECT`[cite: 4]. |

---

## 3. Eventos observados

A partir de `dba.bitacora` se identificaron y analizaron los seis tipos de eventos auditables:

1. **Configuración:** Al recargar parámetros con `pg_reload_conf()`, el proceso principal del servidor registró los cambios de configuración (`parameter "log_statement" changed to "ddl"` y posteriormente a `"mod"`)[cite: 4].
2. **Acceso (fallido y exitoso):** Desde `client=127.0.0.1` se registraron dos intentos fallidos (`FATAL: password authentication failed`) para `app_ventas` (contraseña errónea) y `usuario_inexistente` (`DETAIL: Role "usuario_inexistente" does not exist.`), seguidos de una conexión autenticada vía `scram-sha-256` y autorizada para `app_ventas` (`app=app-ventas-web`)[cite: 4].
3. **Privilegio:** Con `log_statement = 'ddl'` quedaron registradas las sentencias `REVOKE UPDATE ON clientes FROM soporte_ana` (línea `num = 63`) y `GRANT UPDATE ON clientes TO app_ventas` ejecutadas por `postgres`[cite: 4].
4. **Estructura:** Quedó registrada la sentencia `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)` (línea `num = 65`), así como los comandos `ALTER TABLE clientes DISABLE/ENABLE TRIGGER trg_auditoria_clientes`[cite: 4].
5. **Datos:** Con `log_statement = 'mod'` se registró la modificación realizada por `app_ventas` desde `127.0.0.1`: `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` (línea `num = 83`)[cite: 4].
6. **Error:** Gracias a `log_min_error_statement = error`, quedó registrado el intento rechazado de `soporte_ana` de borrar un registro (`ERROR: permiso denegado a la tabla clientes`, línea `num = 99`), el intento de `postgres` de eliminar un rol con privilegios dependientes (`DROP ROLE soporte_ana`) y el intento de `app_ventas` de desactivar el disparador sin ser propietario (`ERROR: debe ser dueño de la tabla clientes`)[cite: 4].

Además, mediante `pg_stat_activity` se comprobó la diferencia entre la **fotografía en tiempo real** (sesión activa de `soporte_ana` ejecutando `SELECT pg_sleep(90)`) y el **historial persistente** en la bitácora (vinculables mediante el `pid`)[cite: 4].

---

## 4. Auditoría del dato

Dado que `log_statement = 'mod'` registra la sentencia SQL pero **no conserva el valor anterior** del dato, se implementó auditoría a nivel de fila en el esquema aislado `auditoria` (`REVOKE ALL ON SCHEMA auditoria FROM PUBLIC`) mediante la tabla `auditoria.cambios_clientes` y el disparador `trg_auditoria_clientes` (`AFTER INSERT OR UPDATE OR DELETE ON clientes FOR EACH ROW`)[cite: 4].

* **Diseño y captura de estado:** La tabla almacena `id_evento`, `momento` (`TIMESTAMPTZ`), `usuario_sesion`, `usuario_efectivo`, `aplicacion`, `ip_cliente` (`INET`), `operacion`, `id_cliente`, `valores_antes` (`JSONB`) y `valores_despues` (`JSONB`)[cite: 4]. Guardar `to_jsonb(OLD)` y `to_jsonb(NEW)` preserva la fila completa incluso si el esquema de `clientes` evoluciona[cite: 4].
* **Papel de `SECURITY DEFINER`, `search_path` y `session_user`:** La función `auditoria.registrar_cambio_cliente()` se creó con `SECURITY DEFINER` y `SET search_path = pg_catalog, public` para permitir que `app_ventas` dispare inserciones en `auditoria.cambios_clientes` sin otorgarle permisos directos de lectura, modificación o borrado sobre el esquema `auditoria`[cite: 4]. Dentro de este contexto, `current_user` devuelve al propietario (`postgres`), por lo que resulta indispensable capturar `session_user` para identificar al usuario real que ejecutó la operación[cite: 4].
* **Resultado del incidente auditado (Actividad 12):** Cuando `app_ventas` ejecutó `UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3`, el evento quedó registrado (`id_evento = 1`, `momento = 2026-11-16 16:11:01.911041-06`, `usuario_sesion = app_ventas`, `aplicacion = app-ventas-web`, `ip_cliente = 127.0.0.1`), permitiendo demostrar mediante `jsonb_each` que el campo `rfc` cambió de **`GAMA780912XYZ`** a **`GAMA780912ZZZ`**, mientras cualquier consulta directa de `app_ventas` sobre `auditoria.cambios_clientes` fue denegada[cite: 4].

---

## 5. Limitaciones

1. **Lecturas no auditadas:** Con `log_statement = 'mod'` y disparadores DML (`INSERT`/`UPDATE`/`DELETE`), las consultas `SELECT` sobre datos sensibles (como `SELECT nombre, rfc, telefono FROM clientes WHERE id = 3` ejecutado por `soporte_ana` en la Actividad 15) no dejan rastro (`lecturas_soporte = 0`)[cite: 4]. Activar `log_statement = 'all'` cubriría lecturas, pero generaría un volumen excesivo y expondría parámetros sensibles en los logs[cite: 4].
2. **Explosión de volumen en operaciones masivas:** Un `UPDATE clientes SET segmento = 'regular'` sin `WHERE` genera **1 sola línea** en `dba.bitacora`, pero inserta **1 fila por cada registro afectado** (5 filas nuevas en la práctica; millones en producción) en `auditoria.cambios_clientes`, impactando almacenamiento e I/O[cite: 4].
3. **Administrador con control total:** Aunque `app_ventas` no pudo borrar registros de auditoría ni deshabilitar el disparador, un superusuario (`postgres`) sí puede ejecutar `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes`, modificar el dato sin dejar rastro en `auditoria.cambios_clientes` y reactivarlo (Actividad 14)[cite: 4].

---

## 6. Riesgos de la bitácora

* **Exposición de secretos y datos sensibles:** En la Actividad 6 se comprobó que ejecutar `CREATE ROLE ... PASSWORD '...'` escribe la contraseña en texto claro dentro de la bitácora (a diferencia del metacomando `\password`, que envía únicamente el verificador SCRAM)[cite: 4]. Asimismo, la bitácora y la tabla de auditoría contienen datos personales (RFC, teléfonos, correos), por lo que su acceso debe restringirse estrictamente[cite: 4].
* **Exportación segura e integridad (Actividad 16):** Para conservar la evidencia fuera del servidor, la bitácora vigente se exportó a `evidencias/bitacora-lab01.log` sustituyendo previamente la contraseña temporal `Temporal_Practica_2026` por `<REDACTED>` mediante `replace()` (verificado sin coincidencias residuales)[cite: 4]. Para garantizar su integridad frente a alteraciones posteriores, se calculó su resumen criptográfico **SHA-256**, almacenado en `evidencias/bitacora-lab01.sha256`:
  * `SHA256: 4DC709AA560CD6E44496576B38C9CEF7AA114C1244EB080EFE2261ED7E9CE4DC`
* **Pérdida local y separación de funciones:** Conservar la bitácora exclusivamente en el servidor que la produce la expone a fallos de disco, rotación automática o borrado por un atacante/administrador comprometido, por lo que debe enviarse a un repositorio externo inmutable administrado por un área independiente[cite: 4].

---

## 7. Cronología y conclusión

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `2026-11-16 ~14:15 CST` | `postgres` (principal) | `::1` | Configuración | Activación de `log_connections`, `log_disconnections`, `log_line_prefix` y `log_statement = 'ddl'` | Sí | `dba.bitacora` (Act. 4)[cite: 4] |
| 2 | `2026-11-16 ~14:22 CST` | `app_ventas` | `127.0.0.1` | Acceso | Intento fallido de autenticación por contraseña incorrecta | No (`FATAL`) | `dba.bitacora` (Act. 5)[cite: 4] |
| 3 | `2026-11-16 14:29:43.635 CST` | `postgres` (`psql`) | `::1` | Privilegio | Revocación preventiva de `UPDATE` sobre `clientes` a `soporte_ana` | Sí | `dba.bitacora` (`num = 63`) |
| 4 | `2026-11-16 14:30:00.457 CST` | `postgres` (`psql`) | `::1` | Estructura | Incorporación de la columna `segmento VARCHAR(20)` a `clientes` | Sí | `dba.bitacora` (`num = 65`) |
| 5 | `2026-11-16 14:51:47.913 CST` | `app_ventas` (`app-ventas-web`) | `127.0.0.1` | Datos | Actualización del teléfono de María García (`id = 3`) a `'6679990000'` | Sí | `dba.bitacora` (`num = 83`) |
| 6 | `2026-11-16 15:10:00.601 CST` | `soporte_ana` (`psql`) | `127.0.0.1` | Error | Intento rechazado de eliminar el registro `id = 5` de `clientes` | No (`ERROR`) | `dba.bitacora` (`num = 99`) |
| 7 | `2026-11-16 16:11:01.911041-06` | `app_ventas` (`app-ventas-web`) | `127.0.0.1` | Datos (auditoría) | Modificación del RFC de María García (`id = 3`) de `GAMA780912XYZ` a `GAMA780912ZZZ` | Sí | `auditoria.cambios_clientes` (`id_evento = 1`) |
| 8 | `2026-11-16 16:20:30.737 CST` | `app_ventas` (`app-ventas-web`) | `127.0.0.1` | Error / Estructura | Intento rechazado de desactivar `trg_auditoria_clientes` sin ser dueño | No (`ERROR`) | `dba.bitacora` (`num = 189–191`) |
| 9 | `2026-11-16 16:21:27.147 CST` | `postgres` (`psql`) | `::1` | Estructura / Datos | Desactivación de disparador, cambio de RFC a `GAMA780912GHI` (`16:21:27.153`) y reactivación | Sí | `dba.bitacora` (`num = 195–196`) |

### Conclusión

**Sí:** con la combinación de bitácora configurada (`logging_collector = on`, `log_connections = on`, `log_line_prefix` completo y `log_statement = 'mod'`) más la tabla de auditoría alimentada por disparador (`auditoria.cambios_clientes`), es posible demostrar con certeza **quién** (`usuario_sesion`), **cuándo** (`momento`), **desde qué IP y aplicación** (`ip_cliente`, `aplicacion`) modificó un dato sensible y **qué valor exacto tenía antes** (`valores_antes`), permitiendo restaurarlo sin ambigüedad[cite: 4]. No obstante, esta capacidad exige que los controles estén activos **antes** del incidente y se complemente con envío externo de bitácoras y separación de funciones para cubrir acciones de superusuarios y lecturas críticas[cite: 4].

---

## Preguntas de reflexión

1. **¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?**
   Porque los mecanismos de registro capturan eventos en tiempo real a medida que ocurren. Si la bitácora o el disparador no estaban activos cuando se ejecutó la operación (como sucedió en la Actividad 3), el evento nunca se escribió y no puede reconstruirse retroactivamente[cite: 4].

2. **¿Por qué conviene que la bitácora la administre el propio servidor y no el mecanismo de despliegue?**
   Porque activar `logging_collector = on` garantiza un manejo uniforme de archivos, rotación y consulta directa mediante funciones SQL (`pg_current_logfile()`, `pg_read_file()`) en cualquier plataforma (Windows, Linux, macOS o contenedores), evitando depender de scripts externos o perder registros al reiniciar contenedores[cite: 4].

3. **¿Por qué el prefijo de línea es tan importante como el nivel de `log_statement`?**
   Porque `log_statement` registra *qué* sentencia se ejecutó, mientras que `log_line_prefix` (`%m [%p] user=%u db=%d app=%a client=%h`) proporciona la atribución indispensable: *cuándo* ocurrió, *quién* se autenticó, en *qué base de datos*, desde *qué aplicación* y *qué dirección IP*, además del PID para correlacionar toda la sesión[cite: 4].

4. **¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?**
   Registrar la sentencia (`log_statement = 'mod'`) guarda el comando SQL ejecutado (una sola línea incluso en actualizaciones masivas), pero no conserva el estado previo ni identifica qué filas concretas cambiaron; registrar el cambio en el dato (`auditoria.cambios_clientes`) guarda el registro completo `OLD` y `NEW` en `JSONB` por cada fila afectada, permitiendo auditar valores exactos y revertir cambios[cite: 4].

5. **¿Qué evidencia ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?**
   `pg_stat_activity` muestra una fotografía instantánea de las sesiones activas en ese preciso momento (incluyendo consultas `SELECT` en curso que `mod` no escribe en el log), pero desaparece al terminar la sesión[cite: 4]. La bitácora conserva el historial cronológico persistente de eventos pasados (accesos fallidos, desconexiones, sentencias y errores) incluso después de cerrarse las conexiones[cite: 4].

6. **Si el administrador puede cambiar `log_statement` a `none` y desactivar el disparador, ¿quién audita al administrador?**
   Un sistema externo centralizado de solo escritura (SIEM o servidor remoto de bitácoras) administrado por un área independiente de operaciones (Seguridad de la Información o Auditoría Interna), respaldado por políticas formales de gestión de cambios y separación de funciones[cite: 4].