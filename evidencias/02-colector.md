# Actividad 2 — Que el servidor administre su propia bitácora

ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';

1. **¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?**
      Porque `logging_collector` arranca un proceso separado del sistema que captura todos los mensajes de error (`stderr`) para guardarlos en archivos desde que enciende PostgreSQL; eso no se puede encender o apagar a mitad de operación. En cambio, `log_statement` es solo una regla que filtra qué comandos guardar, la cual las sesiones leen en memoria al recargar la configuración (`pg_reload_conf()`).

2. **¿Qué ventaja tiene que la bitácora se lea con SQL y no con una herramienta del sistema operativo o del contenedor? ¿Qué riesgo introduce?**
     * **Ventaja:** Puedes filtrar y revisar los registros directamente con consultas SQL desde cualquier cliente, sin importar si el servidor está en Windows, Linux o un contenedor, y sin necesitar permisos de administrador sobre las carpetas del sistema operativo.
     * **Riesgo:** Usa funciones internas (`pg_read_file` / `pg_read_binary_file`) que pueden leer cualquier archivo al que tenga acceso el servicio de PostgreSQL en el disco. Si se dan permisos de más sobre esas funciones o sobre la vista, alguien podría leer archivos confidenciales del servidor.

3. **¿Quién debería poder consultar `dba.bitacora`?**
   Solo el administrador de la base de datos (`postgres`) o un rol dedicado exclusivamente a auditoría. Nunca deben tener acceso los usuarios de las aplicaciones (`app_ventas`), soporte ni `PUBLIC`.