# Actividad 12 — El incidente auditado

1. **Compara tu hipótesis de la Actividad 11 con este resultado.**
   Se confirma la hipótesis: gracias a `SECURITY DEFINER`, el disparador ejecutó la inserción en `auditoria.cambios_clientes` con los privilegios de su propietario (`usuario_efectivo = postgres`), permitiendo que la operación de `app_ventas` quedara auditada sin darle permisos directos sobre el esquema `auditoria` (como se comprobó cuando su `SELECT` fue rechazado con `permiso denegado al esquema auditoria`), mientras que `usuario_sesion` conservó la identidad real (`app_ventas`).

2. **Escribe la sentencia `UPDATE` que restauraría el valor anterior.**

     ```sql
     UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;
     ```

3. **¿Qué columna conserva más valor para una investigación: `aplicacion` o `ip_cliente`? ¿Cuál puede falsificar el cliente con más facilidad?**
   Conserva más valor **`ip_cliente`**, porque la dirección IP la determina la red/socket TCP durante la conexión y no la elige libremente el usuario, mientras que **`aplicacion` (`application_name`)** la puede falsificar el cliente con total facilidad enviando cualquier cadena de texto en su parámetro de conexión (o cambiándola durante la sesión con `SET application_name`).