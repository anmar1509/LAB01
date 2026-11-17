# Actividad 6 — Cambios de privilegios y de estructura

SELECT linea FROM dba.bitacora WHERE linea LIKE '%sentencia:%' ORDER BY num;

 2026-11-16 13:40:37.486 CST [21944] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER SYSTEM SET log_connections = on;
 2026-11-16 13:41:03.896 CST [21944] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER SYSTEM SET log_connections = on;
 2026-11-16 13:41:03.912 CST [21944] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER SYSTEM SET log_disconnections = on;
 2026-11-16 13:41:03.936 CST [21944] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
 2026-11-16 13:41:03.960 CST [21944] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER SYSTEM SET log_statement = 'ddl';
 2026-11-16 13:41:54.628 CST [21944] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER SYSTEM SET log_connections = on;
 2026-11-16 13:42:30.438 CST [21944] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER SYSTEM SET log_connections = on;
 2026-11-16 14:29:43.635 CST [30992] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: REVOKE UPDATE ON clientes FROM soporte_ana;
 2026-11-16 14:29:54.345 CST [30992] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: GRANT UPDATE ON clientes TO app_ventas;
 2026-11-16 14:30:00.457 CST [30992] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
 2026-11-16 14:30:44.938 CST [30992] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';
 2026-11-16 14:30:50.880 CST [30992] user=postgres db=comercial app=psql client=::1 LOG:  sentencia: DROP ROLE rol_temporal;(12 filas)
-- Más  -- 

1. **¿Qué tipo de evento es cada una de las tres primeras sentencias (privilegio o estructura)?**
   * `REVOKE UPDATE ON clientes FROM soporte_ana;`: **Privilegio**.
   * `GRANT UPDATE ON clientes TO app_ventas;`: **Privilegio**.
   * `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);`: **Estructura**.

2. **¿Por qué `GRANT` y `REVOKE` quedan registrados con `log_statement = 'ddl'`?**
   Porque en PostgreSQL el nivel `ddl` de `log_statement` no solo registra las sentencias de definición de objetos (`CREATE`, `ALTER`, `DROP`), sino también las sentencias de control de acceso y permisos sobre dichos objetos (`GRANT`, `REVOKE`, `COMMENT`), ya que alteran la definición y seguridad del esquema.

3. **Si la bitácora contiene contraseñas, ¿quién debería poder leerla? Relaciónalo con la gestión de secretos de la Unidad II.**
   Únicamente el administrador de la base de datos (`postgres`) o personal de seguridad/auditoría estrictamente autorizado, manteniendo los archivos del sistema operativo con permisos restringidos y la vista `dba.bitacora` revocada de `PUBLIC`. Relacionado con la Unidad II, las contraseñas nunca deben viajar en texto claro en sentencias SQL (se debe usar `\password`, gestores de secretos o `.pgpass`), y antes de exportar o compartir bitácoras para análisis se deben sanitizar (`<REDACTED>`).