# Actividad 8 — Errores y operaciones rechazadas

1. **¿El intento de `soporte_ana` causó algún daño? ¿Por qué debe auditarse de todos modos?**
   No causó ningún daño porque PostgreSQL bloqueó la operación por falta de privilegios (`permiso denegado a la tabla clientes`). Sin embargo, debe auditarse porque los intentos fallidos de modificación o borrado revelan posibles errores de configuración de la aplicación, abuso de privilegios o intentos internos/externos de escalamiento o sabotaje antes de que logren tener éxito.

2. **¿Qué diferencia hay entre un error de autorización (esta actividad) y uno de autenticación (Actividad 5)?**
   El error de **autenticación** (Actividad 5) ocurre antes de iniciar la sesión, cuando el servidor rechaza la identidad del usuario (usuario inexistente o contraseña incorrecta, severidad `FATAL`). El error de **autorización** (Actividad 8) ocurre cuando el usuario ya se autenticó correctamente e inició sesión, pero intenta ejecutar una acción sobre un objeto para el cual no tiene permisos otorgados (severidad `ERROR`).

3. **¿Qué indica el error de `DROP ROLE` sobre el orden correcto para dar de baja a un usuario?**
   Indica que en PostgreSQL no se puede eliminar un rol mientras sea propietario de objetos o conserve privilegios asignados en la base de datos. El orden correcto para dar de baja un rol es: primero revocar todos sus privilegios (`REVOKE`), reasignar o eliminar los objetos que le pertenezcan (`REASSIGN OWNED` / `DROP OWNED`), y finalmente ejecutar `DROP ROLE`.