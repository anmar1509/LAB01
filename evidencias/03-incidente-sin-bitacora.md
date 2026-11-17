# Actividad 3 — El incidente sin bitácora

Se ejecutó la actualización del RFC de María García (`id = 3`) desde una sesión de red con el rol `app_ventas`:

UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3;

-- Resultado: UPDATE 1

1. **¿Puedes demostrar quién modificó el RFC?**
   No. Como `log_connections` estaba en `off` y `log_statement` estaba en `none`, el servidor no registró ni el inicio de sesión de `app_ventas` ni la ejecución de la sentencia `UPDATE`, por lo que no existe evidencia de autoría.

2. **¿Puedes demostrar que el cambio no lo hizo `soporte_ana`?**
   Tampoco se puede demostrar con la bitácora. Aunque por reglas de privilegios `soporte_ana` solo tiene permiso `SELECT` sobre `clientes`, al no existir registro de conexiones ni de operaciones no hay evidencia histórica de quién se conectó o actuó en ese momento.

3. **Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?**
   No lo impidieron, y **no debían impedirlo**, porque `app_ventas` es el rol de la aplicación de ventas y necesita el permiso `UPDATE` sobre `clientes` para realizar su operación normal. El control de acceso define qué *puede* hacerse, pero no sustituye a la auditoría para demostrar qué *se hizo* realmente.

4. **¿Qué tendría que haber estado configurado antes del incidente?**
   Debieron estar activos `logging_collector = on`, `log_connections = on`, `log_disconnections = on`, `log_statement = 'mod'` (o `'all'`), y un `log_line_prefix` con usuario (`%u`), base de datos (`%d`), aplicación (`%a`) y cliente (`%h`). Además, para conservar el valor anterior del RFC (`GAMA780912GHI`), era necesario contar con auditoría a nivel de dato (como un disparador hacia una tabla de auditoría).