import 'package:flutter/foundation.dart';

/// Direcciones públicas del backend; aquí nunca se guardan claves de API.
class ApiConfig {
  static const functionsUrl = String.fromEnvironment('FIREBASE_FUNCTIONS_URL');

  static Uri get recommendationsUri {
    if (kIsWeb) {
      return Uri.base.resolve('/api/recommendations');
    }

    final baseUrl = functionsUrl.replaceFirst(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) {
      throw StateError(
        'Define FIREBASE_FUNCTIONS_URL con la URL pública de Firebase Functions.',
      );
    }
    return Uri.parse('$baseUrl/recommendations');
  }
}
