# Actividad 13 — Altas y bajas

1. **El cliente Pedro Ruiz ya no existe en `clientes`. ¿Dónde queda evidencia de que existió y de sus datos?**
   En la tabla `auditoria.cambios_clientes`, específicamente en el registro del evento `INSERT` (en `valores_despues`, donde quedó guardada la fila completa recién creada) y en el registro del evento `DELETE` (en `valores_antes`, donde quedó respaldado el estado completo del registro justo antes de ser eliminado).

2. **¿Por qué `ip_cliente` está vacía en los eventos 2 y 3?**
   Porque las operaciones `INSERT` y `DELETE` se ejecutaron desde la sesión local de administrador (`postgres`) sin utilizar una conexión de red TCP/IP (en Unix/Linux mediante socket local, donde `inet_client_addr()` devuelve `NULL`). *(Nota: si en Windows usaste SQL Shell vía loopback, mostrará `::1` o `127.0.0.1`).*

3. **La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?**
   Aparece un conflicto entre la **minimización/supresión de datos personales** (derecho de cancelación o fin de retención operativa en `clientes`) y la **inmutabilidad de la evidencia de auditoría** (conservar el historial íntegro de quién creó, modificó o borró registros por cumplimiento y seguridad). Este conflicto no debe resolverlo unilateralmente el DBA; deben resolverlo de forma conjunta las áreas de **Cumplimiento / Legal, Seguridad de la Información y el Dueño de los Datos**, definiendo plazos formales de retención diferenciados y mecanismos de anonimización o purga controlada para la tabla de auditoría.