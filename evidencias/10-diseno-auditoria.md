# Actividad 10 — Diseñar y crear el registro de auditoría

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
| :--- | :--- | :--- | :--- |
| `id_evento` | `BIGSERIAL` | **¿En qué orden ocurrió?** (Identificador único y secuencial de cada evento de auditoría). | **No (`NOT NULL`)**, porque es la llave primaria que garantiza la unicidad y el orden cronológico de los registros. |
| `momento` | `TIMESTAMPTZ` | **¿Cuándo?** (Fecha, hora exacta y zona horaria en que se realizó el cambio). | **No (`NOT NULL`)**, porque todo registro de auditoría requiere una marca de tiempo precisa para reconstruir la línea temporal. |
| `usuario_sesion` | `TEXT` | **¿Quién hizo el cambio?** (Rol con el que se autenticó originalmente la sesión). | **No (`NOT NULL`)**, porque siempre existe un usuario autenticado detrás de la sesión que ejecuta la operación. |
| `usuario_efectivo` | `TEXT` | **¿Con qué privilegios efectivos se ejecutó?** (Identifica el rol activo durante la ejecución, como el propietario de una función `SECURITY DEFINER`). | **No (`NOT NULL`)**, porque PostgreSQL siempre evalúa las operaciones bajo un rol efectivo vigente (`current_user`). |
| `aplicacion` | `TEXT` | **¿Desde qué aplicación?** (Nombre del cliente o sistema declarado en `application_name`). | **Sí (`NULL`)**, porque el cliente puede conectarse sin especificar el parámetro `application_name` en su cadena de conexión. |
| `ip_cliente` | `INET` | **¿Desde qué equipo?** (Dirección IP del cliente que originó la conexión). | **Sí (`NULL`)**, porque si la conexión se realiza localmente mediante socket Unix (sin TCP/IP), `inet_client_addr()` devuelve `NULL`. |
| `operacion` | `TEXT` | **¿Qué ocurrió?** (Tipo de acción ejecutada sobre el dato: `INSERT`, `UPDATE` o `DELETE`). | **No (`NOT NULL`)**, porque es indispensable saber qué clase de modificación se realizó sobre el registro. |
| `id_cliente` | `BIGINT` | **¿A qué registro afectó?** (Identificador del cliente modificado en la tabla `clientes`). | **Sí (`NULL`)** (en el diseño de tabla de la práctica se deja opcional por flexibilidad ante operaciones masivas o de esquema, aunque siempre captura `NEW.id` o `OLD.id`). |
| `valores_antes` | `JSONB` | **¿Qué valor tenía el RFC (y demás datos) antes del cambio?** (Estado completo del registro previo a la operación). | **Sí (`NULL`)**, porque en una operación `INSERT` el registro no existía previamente, por lo que no hay valores anteriores. |
| `valores_despues` | `JSONB` | **¿Qué valor quedó después del cambio?** (Estado completo del registro resultante tras la operación). | **Sí (`NULL`)**, porque en una operación `DELETE` el registro deja de existir tras borrarse, por lo que no hay valores posteriores. |

1. **¿Por qué `momento` usa `TIMESTAMPTZ` y no `TIMESTAMP`?**
    Porque `TIMESTAMPTZ` almacena el instante exacto normalizado a UTC junto con el desplazamiento de zona horaria, evitando ambigüedades por cambios de horario de verano, servidores configurados en distintas zonas horarias o clientes conectados desde otras ubicaciones, lo que permite reconstruir una línea temporal precisa y correlacionarla directamente con la bitácora del servidor.

2. **¿Por qué se guarda el registro completo en `JSONB` y no solo la columna que cambió?**
   Porque guardar la fila completa (`to_jsonb(OLD)` y `to_jsonb(NEW)`) conserva el contexto íntegro del registro en ese momento, captura múltiples columnas modificadas en una sola operación y desacopla la tabla de auditoría de futuros cambios de esquema en `clientes` (como agregar o eliminar columnas mediante `ALTER TABLE`), evitando que el disparador falle o que se pierda historial.

3. **La tabla de auditoría también contendrá RFC. ¿Qué implica eso para su clasificación y su control de acceso?**
   Implica que `auditoria.cambios_clientes` hereda el mismo nivel de clasificación confidencial/datos personales sensibles que la tabla `clientes`. En cuanto al control de acceso, debe ubicarse en un esquema aislado (`auditoria`) con privilegios revocados a `PUBLIC`, permitiendo lectura únicamente a roles autorizados de auditoría o administración (`postgres`) y prohibiendo cualquier acceso directo (`SELECT`, `UPDATE` o `DELETE`) a los usuarios operativos de la aplicación (`app_ventas` o `soporte_ana`) para garantizar la confidencialidad e integridad de la evidencia.