# Actividad 9 — Sesiones activas con pg_stat_activity

## Preguntas y respuestas (Actividad 9)

1. **¿Qué columna permite relacionar una sesión con sus líneas de bitácora?**
   La columna `pid` (identificador de proceso del backend), que aparece entre corchetes (`[%p]`, por ejemplo `[12516]`) en cada línea de la bitácora gracias a la configuración de `log_line_prefix`.

2. **Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?**
   La **bitácora del servidor (`dba.bitacora`)**, ya que `pg_stat_activity` solo muestra una fotografía en tiempo real de las conexiones activas en ese instante y elimina la fila en cuanto la sesión finaliza, mientras que la bitácora conserva el historial completo de conexión (`conexión autorizada`) y desconexión (`desconexión`) con su duración exacta (`0:01:30.133`).

3. **¿Por qué `client_addr` aparece vacío en la sesión del administrador?**
   En Windows, como SQL Shell se conecta por loopback TCP/IP local, muestra `::1` o `127.0.0.1` en lugar de vacío.