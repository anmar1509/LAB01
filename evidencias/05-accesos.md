# Actividad 5 — Accesos exitosos y fallidos

SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;

1. **La bitácora registra el usuario `app_ventas` en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?**
   No prueba que haya sido la aplicación legítima. Prueba únicamente que **alguien desde la dirección IP `127.0.0.1` intentó conectarse indicando el nombre de usuario `app_ventas` y proporcionó una contraseña incorrecta**.

2. **¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje que recibe el cliente?**
   Registra una línea `DETALLE` indicando explícitamente que el rol no existe (`No existe el rol «usuario_inexistente»`). No se envía al cliente por seguridad (prevención de enumeración de usuarios): al devolver un mensaje genérico (`la autentificación password falló`), un atacante no puede distinguir si falló el usuario o la contraseña, mientras que el administrador sí conserva el diagnóstico completo en la bitácora.

3. **¿Por qué `app=[desconocido]` en el intento fallido, pero `app=app-ventas-web` en la desconexión?**
   Porque el parámetro `application_name` se procesa y asigna a la sesión **después** de que la autenticación tiene éxito (`conexión autorizada`). En un intento fallido la sesión se rechaza antes de completar esa fase, por lo que el prefijo aún muestra `[desconocido]` (o `[unknown]`).

4. **¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta? Escribe la consulta que contaría los intentos fallidos por usuario.**
   Múltiples errores `FATAL: la autentificación password falló` (o `password authentication failed`) en intervalos de pocos segundos, provenientes de la misma dirección IP (`client=...`), ya sea contra un mismo usuario o probando distintos nombres de usuario.

   ```sql
   SELECT substring(linea FROM 'user=([^ ]+)') AS usuario,
          count(*) AS intentos_fallidos
   FROM dba.bitacora
   WHERE linea ~ 'FATAL:.*(authentication failed|autentificaci.n.*fall)'
   GROUP BY usuario
   ORDER BY intentos_fallidos DESC;