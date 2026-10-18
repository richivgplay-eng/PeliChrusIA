import 'package:flutter/foundation.dart';

/// La web usa el Worker que también sirve sus archivos estáticos.
/// Las apps móviles reciben la URL pública al compilarlas.
class ApiConfig {
  static const workerUrl = String.fromEnvironment('CLOUDFLARE_WORKER_URL');

  static Uri get recommendationsUri {
    if (kIsWeb) {
      return Uri.base.resolve('/api/recommendations');
    }
    if (workerUrl.isEmpty) {
      throw StateError(
        'Define CLOUDFLARE_WORKER_URL con la URL pública del Worker.',
      );
    }
    return Uri.parse(workerUrl).resolve('/api/recommendations');
  }
}
