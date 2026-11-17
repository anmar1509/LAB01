# Actividad 17 — Reconstruir la cronología y responder a Dirección

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente (línea o id_evento) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `2026-11-16 ~14:15 CST` | `postgres` (proceso principal) | `::1` | Configuración | Activación de `log_connections`, `log_disconnections`, `log_line_prefix` y `log_statement = 'ddl'` | Sí | `dba.bitacora` (Actividad 4, líneas previas a `num = 63`) |
| 2 | `2026-11-16 ~14:22 CST` | `app_ventas` | `127.0.0.1` | Acceso | Intento fallido de autenticación por contraseña incorrecta | No (`FATAL`) | `dba.bitacora` (Actividad 5, líneas previas a `num = 63`) |
| 3 | `2026-11-16 14:29:43.635 CST` | `postgres` (`psql`) | `::1` | Privilegio | Revocación preventiva de `UPDATE` sobre `clientes` a `soporte_ana` | Sí | `dba.bitacora` (línea `num = 63`) |
| 4 | `2026-11-16 14:30:00.457 CST` | `postgres` (`psql`) | `::1` | Estructura | Se agregó la columna `segmento VARCHAR(20)` a la tabla `clientes` | Sí | `dba.bitacora` (línea `num = 65`) |
| 5 | `2026-11-16 14:51:47.913 CST` | `app_ventas` (`app-ventas-web`) | `127.0.0.1` | Datos | Actualización del teléfono de María García (`id = 3`) a `'6679990000'` con `log_statement = 'mod'` | Sí | `dba.bitacora` (línea `num = 83`) |
| 6 | `2026-11-16 15:10:00.601 CST` | `soporte_ana` (`psql`) | `127.0.0.1` | Error | Intento rechazado de eliminar el registro `id = 5` de `clientes` | No (`ERROR`) | `dba.bitacora` (línea `num = 99`) |
| 7 | `2026-11-16 16:11:01.911041-06` | `app_ventas` (`app-ventas-web`) | `127.0.0.1` | Datos (auditoría) | Modificación del RFC de María García (`id = 3`) de `GAMA780912XYZ` a `GAMA780912ZZZ` | Sí | `auditoria.cambios_clientes` (`id_evento = 1`) |
| 8 | `2026-11-16 16:20:30.737 CST` | `app_ventas` (`app-ventas-web`) | `127.0.0.1` | Error / Estructura | Intento rechazado de desactivar el disparador `trg_auditoria_clientes` sin ser propietario | No (`ERROR`) | `dba.bitacora` (líneas `num = 189–191`) |
| 9 | `2026-11-16 16:21:27.147 CST` | `postgres` (`psql`) | `::1` | Estructura / Datos | Desactivación temporal de `trg_auditoria_clientes`, cambio de RFC a `GAMA780912GHI` (`16:21:27.153`) y reactivación | Sí | `dba.bitacora` (líneas `num = 195–196`) |

---

## Respuestas a las preguntas de Dirección (Actividad 17)

1. **¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?**
   * **Actividad 3:** **No hay evidencia.** En ese momento `logging_collector` estaba recién activado sin `log_connections` ni `log_statement` (estaba en `'none'`) y aún no existía el disparador de auditoría; por lo tanto, el cambio no quedó registrado en ninguna fuente y constituye un hueco en la cronología.
   * **Actividad 7:** Lo cambió el rol **`app_ventas`** desde `127.0.0.1` usando `app-ventas-web`. Consta en `dba.bitacora` (conexión y desconexión de `app_ventas`), aunque la sentencia `UPDATE` exacta no quedó escrita porque `log_statement` seguía en `'ddl'`.
   * **Actividad 12:** Lo cambió el rol **`app_ventas`** desde `127.0.0.1` usando `app-ventas-web` a las `2026-11-16 16:11:01.911041-06`, registrado tanto en `dba.bitacora` como en `auditoria.cambios_clientes` (`id_evento = 1`).
   * **Actividad 14:** Lo cambió el rol administrador **`postgres`** desde `::1` (`psql`) a las `2026-11-16 16:21:27.153 CST` tras desactivar temporalmente el disparador `trg_auditoria_clientes` (`num = 195–196`); consta en `dba.bitacora`, pero no en `auditoria.cambios_clientes`.

2. **¿Quién cambió el teléfono?**
   * Lo cambió el rol **`app_ventas`** desde `127.0.0.1` usando `app-ventas-web` a las `2026-11-16 14:51:47.913 CST`, registrado en `dba.bitacora` (línea `num = 83`) mediante la sentencia `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` (cuando `log_statement` ya valía `'mod'`). No se registró en `auditoria.cambios_clientes` porque el disparador aún no existía.

3. **¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?**
   * **Sí**, hubo **dos** intentos de acceso fallidos registrados en `dba.bitacora` (Actividad 5), ambos originados desde **`127.0.0.1`** contra la base de datos `comercial`:
     * Uno con el usuario existente **`app_ventas`** (falló por contraseña incorrecta).
     * Uno con el usuario inexistente **`usuario_inexistente`** (falló porque el rol no existe).

4. **¿Qué valor tenía el RFC antes de cada cambio?**
   * **Antes de la Actividad 3:** **No hay evidencia** en la bitácora ni en tablas de auditoría (solo se conoce el valor inicial `GAMA780912GHI` por el script de creación de datos, no por un registro de auditoría).
   * **Antes de la Actividad 7:** **No hay evidencia** en la bitácora (con `log_statement = 'ddl'` no se registró la sentencia ni el estado previo).
   * **Antes de la Actividad 12:** Tenía el valor **`GAMA780912XYZ`**, demostrado en el campo `valores_antes ->> 'rfc'` del registro `id_evento = 1` de `auditoria.cambios_clientes` (donde cambió a `GAMA780912ZZZ`).
   * **Antes de la Actividad 14:** **No hay evidencia directa en la tabla de auditoría** porque el disparador fue desactivado antes del `UPDATE`, aunque por continuidad del último estado registrado en `auditoria.cambios_clientes` (`id_evento = 1`) el valor vigente previo era `GAMA780912ZZZ`.