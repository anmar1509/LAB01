# Actividad 19 — Auditoría de objeto sobre columnas sensibles

1. **¿Por qué no apareció `SELECT nombre, ciudad ...`? ¿Por qué sí apareció `SELECT * ...`?**
   Porque en la auditoría de objeto de `pgaudit`, el rol `auditor_datos` únicamente tiene privilegios `SELECT` sobre las columnas sensibles `rfc` y `telefono`. La consulta `SELECT nombre, ciudad` no toca ninguna columna auditada, por lo que no se registra; en cambio, `SELECT *` expande todas las columnas de la tabla `clientes` (incluyendo `rfc` y `telefono`), activando el registro `AUDIT: OBJECT,...,READ`.

2. **¿Por qué no apareció `UPDATE ... ciudad ...`?**
   Porque `auditor_datos` solo tiene privilegio `UPDATE` sobre las columnas `rfc` y `telefono`. Al actualizar únicamente `ciudad`, no se modifica ninguna columna vigilada por el rol auditor.

3. **¿Qué diferencia de volumen esperarías frente a `log_statement = 'all'`?**
   El volumen generado por `pgaudit` en modo objeto es **drásticamente menor y más selectivo**, ya que solo registra las operaciones que tocan explícitamente las tablas o columnas sensibles asignadas a `auditor_datos`, mientras que `log_statement = 'all'` registra absolutamente todas las consultas (catálogos, healthchecks, lecturas públicas y tablas no críticas) de toda la instancia.

4. **El README oficial advierte que `pgaudit` no puede auditar de forma confiable a los superusuarios (REF-U3-09). ¿Qué implica para la separación de funciones?**
   Implica que un superusuario (`postgres`) puede desactivar `pgaudit` (`ALTER SYSTEM SET pgaudit.log = 'none'`), revocar privilegios a `auditor_datos` o alterar la configuración sin dejar rastro fiable en `pgaudit`. Por ello, el acceso con superusuario debe restringirse al mínimo indispensable (operaciones de emergencia con control de cambios) y las bitácoras deben enviarse en tiempo real a un servidor externo independiente (SIEM) administrado por otro equipo.