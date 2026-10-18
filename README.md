# PeliChrus

App Flutter de recomendaciones con Gemini, TMDB y reconocimiento/voz. La web y
su API se publican juntas en Cloudflare Workers con assets estáticos. Las claves
de Gemini y TMDB se guardan como secretos de Cloudflare, nunca en Flutter ni en
GitHub.

## Coste y límites

Cloudflare Workers ofrece un plan gratuito sin cuota mensual: incluye hasta
100.000 solicitudes del Worker al día; servir archivos estáticos no consume
esa cuota. El plan gratuito tiene límites de CPU y puede cambiar según las
condiciones de Cloudflare. Gemini y TMDB tienen sus propios límites, cuotas y
términos: el backend no los elimina. La API gratuita de TMDB es para uso no
comercial y requiere atribución.
Consulta [los límites y precios de Cloudflare Workers](https://developers.cloudflare.com/workers/platform/pricing/),
[el nivel gratuito de Gemini](https://ai.google.dev/gemini-api/docs/pricing) y
[las condiciones de TMDB](https://developer.themoviedb.org/docs/faq) antes de
publicar el proyecto.

Render también ofrece servicios gratuitos, pero sus web services gratuitos se
apagan tras 15 minutos sin tráfico y tardan alrededor de un minuto en despertar.
Para este backend que depende de Gemini/TMDB, Workers evita esa pausa en el
nivel gratuito. Consulta los [límites gratuitos de Render](https://render.com/docs/free).

El endpoint es accesible públicamente para que pueda llamarlo la app. La
validación y el control de origen ayudan a manejar solicitudes, pero no
garantizan que un tercero no invoque directamente la API. Configura límites de
cuota en Google AI Studio y supervisa el uso de las claves.

## Publicar la web y el backend

1. Crea/inicia sesión en una cuenta de Cloudflare y conecta el repositorio
   `richivgplay-eng/PeliChrusIA`, o usa Wrangler desde PowerShell.
2. Desde la raíz del proyecto instala Wrangler:

   ```powershell
   npm --prefix cloudflare install
   ```

3. Abre una terminal en la carpeta `cloudflare` e inicia sesión:

   ```powershell
   cd cloudflare
   .\node_modules\.bin\wrangler.cmd login
   ```

4. Crea secretos nuevos desde la terminal. Wrangler solicitará cada valor de
   forma interactiva; **no añadas el valor como argumento**:

   ```powershell
   .\node_modules\.bin\wrangler.cmd secret put GEMINI_API_KEY
   .\node_modules\.bin\wrangler.cmd secret put TMDB_API_KEY
   ```

5. Publica el Worker y la aplicación web:

   ```powershell
   npm run deploy
   ```

Wrangler muestra la URL pública al terminar. La web usa el mismo origen para
`/api/recommendations`. Para compilar la app móvil usa esa URL, por ejemplo:

```powershell
flutter run --dart-define="CLOUDFLARE_WORKER_URL=https://pelichrus-api.TU_SUBDOMINIO.workers.dev"
```

Sustituye la URL de ejemplo por la que mostró Wrangler. No uses `--dart-define`
para las claves de Gemini o TMDB.

## Verificación

```powershell
cd cloudflare
npm test
```

## Seguridad de claves

Las claves publicadas anteriormente en mensajes deben considerarse
comprometidas: revócalas y crea reemplazos antes de configurar los secretos.
No las subas a GitHub, no las escribas en los comandos y no las compartas aquí.
El Worker tampoco elimina los límites ni términos de uso de Gemini o TMDB.

## Imágenes y atribución

Los avatares están en `assets/`: `chrus_neutral.png`, `chrus_feliz.png`,
`chrus_pensando.png` y `chrus_triste.png`. El logo `logo_pelichrus.png` es
opcional; sin él se muestra el nombre de la app.

La aplicación muestra la atribución requerida: «Este producto utiliza la API
de TMDB, pero no está respaldado ni certificado por TMDB».
