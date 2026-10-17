import 'package:flutter/foundation.dart';

/// Direcciones públicas del backend; aquí nunca se guardan claves de API.
class ApiConfig {
  static const functionsUrl = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-pelichrusia.cloudfunctions.net/api',
  );

  static Uri get recommendationsUri {
    if (kIsWeb) {
      return Uri.base.resolve('/api/recommendations');
    }

    final baseUrl = functionsUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$baseUrl/recommendations');
  }
}
