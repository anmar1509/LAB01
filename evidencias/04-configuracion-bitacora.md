# Actividad 4 — Configurar la bitácora

SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');

1. **¿Por qué el proceso que registra el cambio es el principal y no tu sesión?**
   Porque `pg_reload_conf()` envía una señal de recarga (`SIGHUP`) al proceso principal (*postmaster*) del servidor, que es quien lee los archivos de configuración, aplica los cambios globales y notifica a los demás procesos.

2. **¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?**
   Sí quedaría rastro. Por un lado, al momento de ejecutar `ALTER SYSTEM` aún sigue vigente `log_statement = 'ddl'`, por lo que se registra la sentencia; por otro lado, al recargar la configuración (`pg_reload_conf()`), el proceso principal registra automáticamente en la bitácora el evento `LOG: parameter "log_statement" changed to "none"`.

3. **¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?**
   Porque ese archivo es administrado exclusivamente por el servidor mediante `ALTER SYSTEM` (incluye un encabezado de advertencia). Editarlo manualmente puede introducir errores de sintaxis que impidan recargar o iniciar el servicio, además de que cualquier `ALTER SYSTEM` posterior puede sobrescribir o reorganizar su contenido.