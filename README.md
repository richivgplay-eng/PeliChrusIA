# PeliChrus

Aplicación Flutter de recomendaciones de películas con Gemini, TMDB, voz y
reconocimiento de voz. El proyecto incluye destinos para Android, iOS y Web.

## Requisitos

- Flutter instalado.
- Una clave de API de Gemini y una clave API v3 de TMDB.

## Ejecutar

Desde la raíz del proyecto, en PowerShell, pasa las claves al ejecutar la app:

```powershell
flutter run --dart-define="GEMINI_API_KEY=TU_CLAVE_GEMINI" --dart-define="TMDB_API_KEY=TU_CLAVE_TMDB"
```

Para generar la versión web:

```powershell
flutter build web --dart-define="GEMINI_API_KEY=TU_CLAVE_GEMINI" --dart-define="TMDB_API_KEY=TU_CLAVE_TMDB"
```

Las claves se leen en `lib/api_config.dart` y no se guardan en el repositorio.
No las agregues directamente al código ni las publiques: los valores `dart-define`
incluidos en una aplicación cliente pueden extraerse del artefacto compilado.
Para producción, usa un backend para proteger las claves.

## Imágenes

Coloca los recursos en `assets/`:

- `chrus_neutral.png`
- `chrus_feliz.png`
- `chrus_pensando.png`
- `chrus_triste.png`
- `logo_pelichrus.png` (opcional; se muestra el nombre si no está disponible)

La carpeta está declarada en `pubspec.yaml`.
