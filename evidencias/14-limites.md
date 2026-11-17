# Actividad 15 — Límites: lecturas y volumen

1. **Si `clientes` tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un `UPDATE` sin `WHERE`?**
   Porque el disparador está definido como `FOR EACH ROW`, insertaría **un millón de filas nuevas** en `auditoria.cambios_clientes` dentro de la misma transacción (guardando dos documentos `JSONB` completos por cada registro modificado). Esto provocaría un crecimiento explosivo en el tamaño de la tabla de auditoría, una fuerte degradación del rendimiento de escritura (I/O y WAL) e incluso podría agotar el espacio en disco disponible.

2. **Propón quién podría autorizar la depuración de `auditoria.cambios_clientes`.**
   No debe autorizarla el DBA por cuenta propia; debe ser una autorización formal y documentada emitida de manera conjunta por el **Oficial de Seguridad de la Información (CISO), el área de Cumplimiento / Legal (o Auditoría Interna) y el Dueño de los Datos**, respaldada por un ticket aprobado y archivando previamente un respaldo íntegro con verificación de hash.

3. **¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?**
   Porque al registrar todas las sentencias SQL ejecutadas, quedan escritos en texto plano dentro de los archivos de log los parámetros literales de las consultas y filtros (como búsquedas por `RFC`, `CURP`, números de tarjeta, correos electrónicos o contraseñas enviadas en sentencias), replicando información confidencial fuera de las tablas protegidas de la base de datos.