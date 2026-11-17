# Actividad 14 — Intentar manipular la auditoría

1. **¿Qué evidencia permite detectar que hubo un cambio sin auditar?**
   La **bitácora del servidor (`dba.bitacora`)**, donde quedaron registradas en secuencia cronológica las sentencias `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes`, el `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3` ejecutado durante esa ventana y la posterior reactivación `ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes`, además de la discrepancia entre el valor actual del registro en `clientes` y el último estado registrado en `auditoria.cambios_clientes`.

2. **¿Qué control administrativo (no técnico) reduciría este riesgo?**
   Establecer un procedimiento formal de **gestión de cambios y revisión periódica de bitácoras por un área independiente** (como Seguridad de la Información o Auditoría Interna), exigiendo tickets aprobados para cualquier ventana de mantenimiento sobre objetos de auditoría y revisando alertas ante comandos `DISABLE TRIGGER` o cambios de configuración.

3. **Relaciona esta actividad con el principio de separación de funciones de la Unidad II.**
   El principio de separación de funciones establece que ninguna persona que opera o administra la base de datos debe poder borrar o ocultar la evidencia de sus propias acciones. Aunque `app_ventas` quedó bloqueada por permisos, un administrador con control total (`postgres`) sí puede desactivar temporalmente el disparador; por ello, las bitácoras deben enviarse a un repositorio externo centralizado (SIEM o servidor de logs) administrado por un equipo distinto al DBA.