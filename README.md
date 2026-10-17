# PeliChrus

Aplicación Flutter multiplataforma de recomendaciones de películas. Gemini
genera las sugerencias y TMDB aporta información, pósteres y disponibilidad en
Colombia. Las claves de ambos servicios se leen únicamente desde Firebase
Functions Secret Manager; no se incluyen en Flutter ni en el repositorio.

## Requisitos

- Flutter instalado.
- Node.js 22 o superior y npm.
- Firebase CLI (`npm install -g firebase-tools`).
- Un proyecto de Firebase con el plan Blaze habilitado para desplegar Cloud
  Functions. Configura alertas y límites de presupuesto en Google Cloud.
- Claves de Gemini y TMDB. No las guardes en archivos del proyecto.

## Configuración y despliegue

Inicia sesión y averigua el ID de tu proyecto:

```powershell
firebase login
firebase projects:list
```

Instala las dependencias del backend:

```powershell
npm --prefix functions install
npm --prefix functions test
```

Guarda las claves interactivamente en Firebase Secret Manager. La CLI te
solicita cada valor; no lo agregues como argumento al comando:

```powershell
firebase functions:secrets:set GEMINI_API_KEY --project TU_PROJECT_ID
firebase functions:secrets:set TMDB_API_KEY --project TU_PROJECT_ID
```

Compila Flutter Web y despliega Functions y Hosting:

```powershell
flutter build web
firebase deploy --only functions,hosting --project TU_PROJECT_ID
```

La web quedará en `https://TU_PROJECT_ID.web.app`. Firebase Hosting dirige las
peticiones `/api/recommendations` al backend. Functions está en la región
`us-central1`.

El endpoint aplica validación de texto, CORS y un límite básico de consultas
por IP en cada instancia. El límite en memoria no sustituye Firebase App Check
y no impide por sí solo el uso automatizado desde clientes externos. Antes de
compartir ampliamente la app, configura App Check para web, Android e iOS y
activa presupuestos/alertas de facturación en Google Cloud.

Para ejecutar Android o iOS contra el backend desplegado, usa la URL base
pública de la función (no es una clave):

```powershell
flutter run --dart-define="FIREBASE_FUNCTIONS_URL=https://us-central1-TU_PROJECT_ID.cloudfunctions.net/api"
```

La URL también se puede establecer en la configuración de ejecución de VS Code.
No pases `GEMINI_API_KEY` ni `TMDB_API_KEY` a Flutter: el backend los lee como
secretos gestionados por Firebase.

## Probar las funciones localmente

Crea `functions/.secret.local` con este formato:

```dotenv
GEMINI_API_KEY=tu_clave_de_gemini
TMDB_API_KEY=tu_clave_de_tmdb
```

Ese archivo está excluido de Git. No pegues claves en el código ni lo subas a
GitHub. Inicia los emuladores con:

```powershell
firebase emulators:start --only functions,hosting --project TU_PROJECT_ID
```

## Imágenes

Las imágenes de Chrus viven en `assets/`: `chrus_neutral.png`,
`chrus_feliz.png`, `chrus_pensando.png` y `chrus_triste.png`. El logo
`logo_pelichrus.png` es opcional; si falta, se muestra el nombre de la app.

La aplicación atribuye a TMDB el origen de sus datos. Consulta sus condiciones
antes de publicar o monetizar el servicio: su API gratuita para desarrolladores
es para uso no comercial.
