# Actividad 7 — Modificaciones de datos: ddl frente a mod

1. **¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?**
   El nivel `log_statement = 'all'`. En un servidor con miles de consultas por minuto, registrar todas las sentencias `SELECT` tendría un costo muy alto: generaría un volumen masivo de escritura en disco (I/O), saturaría rápidamente el almacenamiento destinado a bitácoras, degradaría el rendimiento general del motor y dificultaría localizar eventos críticos entre millones de consultas rutinarias, además de incrementar el riesgo de exponer datos sensibles.

2. **¿Qué le falta a esta bitácora para revertir el cambio con certeza? (Lo resolverás en la Parte B.)**
   Le falta registrar el **valor anterior (`OLD`)** del campo antes de ser modificado. La bitácora del servidor únicamente guarda la sentencia ejecutada (`UPDATE clientes SET telefono = '6679990000' WHERE id = 3`), por lo que muestra el valor nuevo que se escribió, pero no conserva el dato original necesario para restaurarlo.