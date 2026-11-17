# Actividad 1 — Configuración de registro por defecto

SELECT name, setting, source FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
'log_connections', 'log_disconnections', 'log_line_prefix',
'log_statement', 'log_min_error_statement', 'log_timezone') ORDER BY name;

1. **Con esta configuración, ¿se registra quién se conecta?**
   **No**, porque `log_connections` está en `off` (al igual que `log_disconnections`).

2. **¿Se registran las sentencias UPDATE?**
   **No**, porque `log_statement` está en `none`. Solo se registrarían si provocaran un error (`log_min_error_statement = error`).

3. **¿La línea de bitácora incluye el usuario o la dirección IP del cliente?**
   **No**, porque `log_line_prefix` solo tiene `%m [%p]` (fecha/hora y PID). Faltan los marcadores `%u` (usuario) y `%h` (host/IP).

4. **¿En qué zona horaria se registran los eventos? ¿Por qué importa al reconstruir una cronología?**
  En **`America/Chihuahua`**. Importa porque permite sincronizar las horas de la base de datos con las bitácoras de otros servidores, aplicaciones o redes que usen otra zona horaria (como UTC) para armar una línea de tiempo exacta.

5. **Con `logging_collector = off`, ¿quién decide dónde termina la bitácora: PostgreSQL o el mecanismo con que se desplegó el servidor?**
   El mecanismo con que se desplegó el servidor (sistema operativo, servicio o contenedor), ya que PostgreSQL solo envía los mensajes a `stderr` y el entorno decide dónde guardarlos.

