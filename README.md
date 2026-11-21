# Rubípticos

Sitio para jugar crípticos en español, hecho en Ruby on Rails 8.1 (TFI de TTPS opción Ruby, cursada 2026).

## Catálogo de crípticos y sincronización

El catálogo se trae de la API JSON de la cátedra ([ecorrons/cryptics-api](https://github.com/ecorrons/cryptics-api)) **por HTTP** y se guarda en la base. El juego siempre lee los crípticos de la base: la API solo se consulta al sincronizar.

La lógica está en el servicio `SincronizadorDeCripticos` (`app/services/sincronizador_de_cripticos.rb`). Lo usan:

- `bin/rails db:setup` / `bin/rails db:seed`, para la carga inicial (`db/seeds/cripticos.rb`);
- la tarea `cripticos:sincronizar`;
- el botón «Sincronizar ahora» del admin.

### Qué hace

1. Hace un GET a la URL de la fuente con un timeout de 10 s y sigue hasta 3 redirecciones.
2. Si falla la red, la respuesta no es 2xx o el JSON no tiene `version` y `cripticos`, **no toca nada** y registra la sincronización como `fallida`, con el error.
3. Si la `version` es igual a la de la última sincronización exitosa, registra `sin_cambios` y termina.
4. Dentro de una transacción, para cada críptico, identificado por su `id` de la fuente:
   - si no existe, lo crea;
   - si existe y cambió, lo actualiza;
   - si es igual, no hace nada. Por eso sincronizar dos veces lo mismo no cambia nada (es idempotente).
5. Un críptico inválido, o con el `id` repetido en el JSON, se saltea y se informa con su `id` y el motivo. Los demás se procesan igual.
6. Los crípticos que ya no vienen en la fuente **no se borran**, porque pueden tener partidas jugadas: se marcan `en_fuente: false`.
7. Cada sincronización queda en la tabla `sincronizaciones` con:
   - fecha;
   - usuario que la pidió;
   - URL y versión;
   - estado;
   - cantidad de creados, actualizados, desactivados y rechazados;
   - el detalle de los rechazados.

### Validaciones de un críptico

Están en el modelo `Criptico` y, las básicas, también en la base (NOT NULL, índice único en `id_fuente` y checks de `tipo` y `dificultad`):

- `enunciado`, `enumeracion`, `respuesta`, `tipo` y `dificultad` son obligatorios. `tipo` y `dificultad` tienen que ser valores conocidos.
- La enumeración, por ejemplo `(6)` o `(4,5)`, suma lo mismo que el largo de la respuesta, sin contar tildes, espacios ni signos.
- Cada definición, indicador y material aparece en el enunciado.
- Hay al menos una definición, y exactamente dos en una `doble_definicion`.
- Reglas por tipo, en `VerificadorDeCriptico`:
  - **oculta**: la respuesta está escrita de corrido en el material.
  - **anagrama**: el material tiene exactamente las mismas letras que la respuesta.
  - **iniciales** y **finales**: las primeras o últimas letras de las palabras del material forman la respuesta.

### Comandos

En Linux, macOS o WSL:

```bash
bin/rails cripticos:sincronizar                    # usa la URL configurada
bin/rails "cripticos:sincronizar[https://ecorrons.github.io/cryptics-api/v1/cryptics_with_errors.json]"
CRIPTICOS_URL=http://localhost:8000/v1/cryptics.json bin/rails db:seed
```

En Windows, con PowerShell:

```powershell
ruby bin\rails cripticos:sincronizar
ruby bin\rails "cripticos:sincronizar[https://ecorrons.github.io/cryptics-api/v1/cryptics_with_errors.json]"
$env:CRIPTICOS_URL = "http://localhost:8000/v1/cryptics.json"; ruby bin\rails db:seed
```

La URL que se usa, en orden de prioridad:

1. El argumento de la tarea rake.
2. La variable de entorno `CRIPTICOS_URL`.
3. Por defecto, `https://ecorrons.github.io/cryptics-api/v1/cryptics.json`.

`db:seed` necesita internet porque va a la API real. Para trabajar sin conexión:
1. Clonar `cryptics-api`.
2. Servirlo con WEBrick, como explica su README.
3. Apuntar `CRIPTICOS_URL` a ese servidor. Ajustar el puerto al que use.

### Prueba con el catálogo con errores

`cryptics_with_errors.json` sirve para comprobar que los errores se detectan e informan. Sobre una base vacía crea **1** críptico y rechaza **6**:

| id | motivo |
|---|---|
| cr-102 | la enumeración no coincide con la respuesta |
| cr-103 | el material no es anagrama de la respuesta |
| cr-104 | falta la respuesta |
| cr-105 | tipo y dificultad desconocidos |
| cr-101 (2.º) | id repetido en el catálogo |
| cr-107 | una definición no aparece en el enunciado |

Los tests del servicio no usan internet. Inyectan un cliente HTTP falso o levantan un servidor HTTP local, y leen copias del catálogo de `test/fixtures/files/`:

```bash
bin/rails test test/services/sincronizador_de_cripticos_test.rb test/models/criptico_test.rb test/models/sincronizacion_test.rb
```

### Decisiones de diseño

- **Dos flags: `activo` y `en_fuente`.**
  - `activo` lo maneja el admin a mano. `en_fuente` lo maneja la sincronización.
  - Un críptico que vuelve a aparecer en la API se reactiva solo, pero uno que el admin apagó no lo reactiva la sync.
  - Para jugar se usa `Criptico.jugables`, que exige los dos.
- **Un críptico que ya existía y llega inválido se rechaza y conserva su versión anterior.** No se desactiva, porque sí vino en la fuente.
- **Las sincronizaciones fallidas también se registran**, para tener el historial. No cuentan para decidir «Sin cambios».
- **Los fragmentos se comparan con el enunciado sin distinguir mayúsculas.** Así, «Al principio» al comienzo del enunciado coincide con «al principio» en la lista de indicadores. El resto del texto tiene que coincidir tal cual.
- **Enums guardados como texto** (`tipo`, `dificultad`, `estado`), con un check constraint en la base. Un valor desconocido da un error de validación, no una excepción.
- **Las reglas por tipo están en `VerificadorDeCriptico`**, como funciones puras, para testearlas y explicarlas aparte del modelo.
- **El cliente HTTP se puede inyectar en el servicio**, así se testea sin internet y sin gemas extra.

## Backend de administración

Se entra en `/admin` con email y contraseña. No hay registro público: el primer admin lo crea `bin/rails db:setup` (o `bin/rails db:seed`).

**Admin de prueba:** `admin@rubipticos.com` / `admin1234`. Se pueden cambiar con las variables de entorno `ADMIN_EMAIL` y `ADMIN_PASSWORD` al correr los seeds.

### Qué puede hacer cada rol

| Sección | Administrador | Editor de puntajes |
|---|---|---|
| Puntajes (puntos por tipo y multiplicadores) | ✅ | ✅ |
| Crípticos (listado con filtros, activar/desactivar) | ✅ | ❌ |
| Configuración (URL de la fuente, texto de bienvenida) | ✅ | ❌ |
| Sincronización («Sincronizar ahora», historial e informe) | ✅ | ❌ |
| Jugadores (bloquear nombres, reiniciar la tabla) | ✅ | ❌ |
| Usuarios del backend (alta, edición, rol, desactivar) | ✅ | ❌ |

### Decisiones de diseño

- **Login con el generador de Rails 8** (`bin/rails g authentication`). El modelo queda como `User`, como lo genera Rails, con `rol` (`admin` o `editor_puntajes`) y `activo`, validados en el modelo y con un check constraint en la base. Se sacó el reset de contraseña porque no hay mailer.
- **Permisos en el servidor.** Todos los controladores del admin heredan de `Admin::BaseController`, que exige login y por defecto deja entrar solo al admin. Los que también usa el editor lo declaran con `permitir_roles :admin, :editor_puntajes`. Si un editor escribe a mano la URL de otra sección, lo redirige con un aviso.
- **Un usuario desactivado no puede entrar**, y si tenía una sesión abierta deja de valer.
- **Siempre queda al menos un admin activo**: el modelo no deja desactivar ni pasar a editor al último.
- **Los usuarios no se borran**, se desactivan.
- **La configuración es una sola fila** (`Configuracion.actual`), garantizada también con un check en la base.
- **«Sincronizar ahora» usa la URL guardada en Configuración** y llama al servicio `SincronizadorDeCripticos` del catálogo; el controlador no tiene lógica de sincronización.
- **Reiniciar la tabla no borra nada**: guarda la fecha en `Configuracion.tabla_reiniciada_at` y la tabla de posiciones cuenta solo las partidas resueltas después.
