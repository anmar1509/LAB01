CREATE OR REPLACE FUNCTION auditoria.registrar_cambio_cliente()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
	BEGIN
	IF TG_OP = 'INSERT' THEN
	INSERT INTO auditoria.cambios_clientes (operacion, id_cliente, valores_despues)
	VALUES (TG_OP, NEW.id, to_jsonb(NEW));
	RETURN NEW;
	ELSIF TG_OP = 'UPDATE' THEN
	INSERT INTO auditoria.cambios_clientes (operacion, id_cliente, valores_antes, valores_despues)
	VALUES (TG_OP, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
	RETURN NEW;
	ELSIF TG_OP = 'DELETE' THEN
	INSERT INTO auditoria.cambios_clientes (operacion, id_cliente, valores_antes)
	VALUES (TG_OP, OLD.id, to_jsonb(OLD));
	RETURN OLD;
	END IF;
	RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION auditoria.registrar_cambio_cliente() FROM PUBLIC;
CREATE TRIGGER trg_auditoria_clientes
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION auditoria.registrar_cambio_cliente();

SELECT tgname, tgenabled, tgrelid::regclass FROM pg_trigger WHERE NOT tgisinternal;

/*

1. ¿Por qué se ejecuta `REVOKE ALL ON FUNCTION ... FROM PUBLIC` si el disparador seguirá funcionando para `app_ventas`?
   Porque en PostgreSQL cualquier rol en `PUBLIC` tiene permiso `EXECUTE` por defecto sobre las funciones recién creadas.
   Revocarlo impide que un usuario llame directamente a `auditoria.registrar_cambio_cliente()` de forma manual fuera del contexto 
   del disparador, mientras que el disparador sigue ejecutándose automáticamente porque lo invoca el propio motor como propietario
   del trigger (`postgres`), no el usuario final.

2. ¿Qué pasaría si la función no fuera `SECURITY DEFINER`? Formula una hipótesis antes de la Actividad 12.
   Si la función fuera `SECURITY INVOKER` (el comportamiento por defecto), se ejecutaría con los privilegios del usuario que realiza
   la modificación (por ejemplo, `app_ventas`). Como `app_ventas` no tiene permiso `USAGE` sobre el esquema `auditoria` ni `INSERT` sobre 
   `auditoria.cambios_clientes`, el disparador fallaría con `ERROR: permission denied for schema auditoria` y abortaría toda la 
   transacción (`UPDATE`, `INSERT` o `DELETE`) sobre `clientes`.

3. Consulta `dba.bitacora`. ¿Quedó registrada la creación del esquema, la tabla, la función y el disparador? ¿Por qué?
   Sí, quedaron registradas las cuatro sentencias (`CREATE SCHEMA`, `CREATE TABLE`, `CREATE FUNCTION` y `CREATE TRIGGER`) porque el
   parámetro `log_statement` está configurado en `'mod'`, nivel que incluye todas las sentencias de definición de datos (`ddl`) además
   de las modificaciones de registros (`INSERT`, `UPDATE`, `DELETE`).
   
   
 */