/// Lee las claves desde `--dart-define` para no guardarlas en el repositorio.
class ApiConfig {
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
}
