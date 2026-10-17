import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

import 'api_config.dart';
import 'widgets/tarjeta_pelicula_widget.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  static const _colorBurbujaUsuario = Color(0xFF263442);
  static const _colorBurbujaChrus = Color(0xFF123B4A);

  final TextEditingController _controladorTexto = TextEditingController();
  final FlutterTts _voz = FlutterTts();
  final SpeechToText _reconocimientoVoz = SpeechToText();
  final http.Client _clienteHttp = http.Client();
  final List<_MensajeChat> _mensajes = [
    const _MensajeChat(
      texto: '¡Hola! Soy Chrus. Cuéntame qué te gustaría ver y te recomiendo '
          'algunas películas.',
      esUsuario: false,
    ),
  ];
  List<_Pelicula> _peliculas = [];
  String estadoChrus = 'neutral';
  bool _escuchando = false;
  bool _enviando = false;

  static const Map<String, String> _assetsAvatar = {
    'neutral': 'assets/chrus_neutral.png',
    'feliz': 'assets/chrus_feliz.png',
    'pensando': 'assets/chrus_pensando.png',
    'triste': 'assets/chrus_triste.png',
  };

  @override
  void initState() {
    super.initState();
    _configurarVoz();
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _clienteHttp.close();
    _voz.stop();
    _reconocimientoVoz.stop();
    super.dispose();
  }

  Future<void> _configurarVoz() async {
    try {
      await _voz.setLanguage('es-CO');
      await _voz.setPitch(1.2);
      await _voz.setSpeechRate(0.55);
    } on PlatformException catch (error) {
      _mostrarError('No se pudo configurar la voz: ${error.message}');
    } on MissingPluginException catch (error) {
      _mostrarError('El plugin de voz no está disponible: ${error.message}');
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _controladorTexto.text.trim();
    if (texto.isEmpty || _enviando) return;

    _controladorTexto.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _mensajes.add(_MensajeChat(texto: texto, esUsuario: true));
    });
    await _enviarMensajeAGemini(texto);
  }

  Future<void> _enviarMensajeAGemini(String texto) async {
    setState(() {
      _enviando = true;
      estadoChrus = 'pensando';
    });

    try {
      final resultado = await _consultarGemini(texto);
      final respuesta = resultado['respuesta']! as String;
      final titulos = resultado['titulos']! as List<String>;

      if (!mounted) return;
      setState(() {
        estadoChrus = 'feliz';
        _mensajes.add(_MensajeChat(texto: respuesta, esUsuario: false));
      });
      try {
        await _buscarEnTMDB(titulos);
      } on _ApiException catch (error) {
        _mostrarError(error.message);
      } on http.ClientException catch (error) {
        _mostrarError('No se pudo conectar con TMDB: ${error.message}');
      } on FormatException catch (error) {
        _mostrarError('TMDB devolvió una respuesta inválida: ${error.message}');
      }

      try {
        await _voz.speak(respuesta);
      } on PlatformException catch (error) {
        _mostrarError('No se pudo reproducir la voz: ${error.message}');
      }
    } on _ApiException catch (error) {
      _mostrarError(error.message);
      if (mounted) {
        setState(() {
          estadoChrus = 'triste';
          _mensajes.add(
            const _MensajeChat(
              texto: 'No pude obtener una respuesta. Revisa la conexión y la '
                  'configuración de Gemini.',
              esUsuario: false,
            ),
          );
        });
      }
    } on http.ClientException catch (error) {
      _mostrarError('No se pudo conectar con Gemini: ${error.message}');
      if (mounted) {
        setState(() {
          estadoChrus = 'triste';
          _mensajes.add(
            const _MensajeChat(
              texto: 'Lo siento, tuve un problema al preparar la respuesta.',
              esUsuario: false,
            ),
          );
        });
      }
    } on FormatException catch (error) {
      _mostrarError('Gemini devolvió una respuesta inválida: ${error.message}');
      if (mounted) {
        setState(() {
          estadoChrus = 'triste';
          _mensajes.add(
            const _MensajeChat(
              texto: 'No pude interpretar la respuesta de Gemini.',
              esUsuario: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
          if (estadoChrus == 'pensando') estadoChrus = 'neutral';
        });
      }
    }
  }

  Future<Map<String, Object>> _consultarGemini(String texto) async {
    final apiKey = ApiConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw const _ApiException(
        'Falta GEMINI_API_KEY. Inicia la app con --dart-define.',
      );
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/gemini-2.5-flash:generateContent',
      {'key': apiKey},
    );
    final response = await _clienteHttp.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Eres Chrus, un asistente de cine amable para Colombia. '
                    'Responde en español a esta petición: "$texto". '
                    'Recomienda hasta tres películas conocidas y devuelve '
                    'únicamente un objeto JSON con "respuesta" (string) y '
                    '"titulos" (array de strings con títulos de películas).',
              },
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );
    final data = _decodificarRespuesta(response, 'Gemini');
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const _ApiException('Gemini no devolvió ninguna recomendación.');
    }

    final candidate = candidates.first;
    if (candidate is! Map<String, dynamic>) {
      throw const _ApiException(
          'La respuesta de Gemini no tiene el formato esperado.');
    }
    final content = candidate['content'];
    if (content is! Map<String, dynamic> || content['parts'] is! List) {
      throw const _ApiException('Gemini devolvió una respuesta vacía.');
    }
    final parts = content['parts'] as List<dynamic>;
    if (parts.isEmpty || parts.first is! Map<String, dynamic>) {
      throw const _ApiException('Gemini devolvió una respuesta vacía.');
    }

    final generatedText = (parts.first as Map<String, dynamic>)['text'];
    if (generatedText is! String) {
      throw const _ApiException('Gemini no devolvió texto para procesar.');
    }
    final decodedText = jsonDecode(generatedText);
    if (decodedText is! Map<String, dynamic> ||
        decodedText['respuesta'] is! String ||
        decodedText['titulos'] is! List) {
      throw const _ApiException(
          'Gemini devolvió recomendaciones con formato inválido.');
    }

    final titulos =
        (decodedText['titulos'] as List<dynamic>).whereType<String>().toList();
    if (titulos.isEmpty) {
      throw const _ApiException('Gemini no encontró títulos para recomendar.');
    }
    return {
      'respuesta': decodedText['respuesta'] as String,
      'titulos': titulos,
    };
  }

  Future<void> _buscarEnTMDB(List<String> titulos) async {
    final apiKey = ApiConfig.tmdbApiKey;
    if (apiKey.isEmpty) {
      throw const _ApiException(
        'Falta TMDB_API_KEY. Inicia la app con --dart-define.',
      );
    }

    final resultados = await Future.wait(
      titulos.take(5).map((titulo) => _buscarPeliculaEnTMDB(titulo, apiKey)),
    );

    if (!mounted) return;
    setState(() {
      _peliculas = resultados.whereType<_Pelicula>().toList();
    });
  }

  Future<_Pelicula?> _buscarPeliculaEnTMDB(
    String titulo,
    String apiKey,
  ) async {
    final uri = Uri.https('api.themoviedb.org', '/3/search/movie', {
      'api_key': apiKey,
      'query': titulo,
      'language': 'es-CO',
      'region': 'CO',
      'include_adult': 'false',
    });
    final data = _decodificarRespuesta(
      await _clienteHttp.get(uri),
      'TMDB',
    );
    final results = data['results'];
    if (results is! List || results.isEmpty) return null;

    final movie = results.first;
    if (movie is! Map<String, dynamic> || movie['id'] is! num) return null;
    final id = (movie['id'] as num).toInt();
    final title = movie['title'] is String ? movie['title'] as String : titulo;
    final posterPath = movie['poster_path'];
    final posterUrl = posterPath is String
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';
    final releaseDate = movie['release_date'];
    final anio = releaseDate is String && releaseDate.length >= 4
        ? releaseDate.substring(0, 4)
        : 'Año desconocido';
    final rating = movie['vote_average'];
    final puntuacion = rating is num ? rating.toStringAsFixed(1) : 'N/D';

    final plataforma = await _obtenerPlataformasTMDB(id, apiKey);
    final trailerUrl = Uri.https(
      'www.youtube.com',
      '/results',
      {'search_query': '$title tráiler'},
    ).toString();

    return _Pelicula(
      titulo: title,
      posterUrl: posterUrl,
      plataforma: plataforma,
      trailerUrl: trailerUrl,
      anio: anio,
      puntuacion: puntuacion,
    );
  }

  Future<String> _obtenerPlataformasTMDB(int id, String apiKey) async {
    final uri =
        Uri.https('api.themoviedb.org', '/3/movie/$id/watch/providers', {
      'api_key': apiKey,
    });
    final data = _decodificarRespuesta(
      await _clienteHttp.get(uri),
      'TMDB',
    );
    final results = data['results'];
    if (results is! Map<String, dynamic>) return 'No reportada por TMDB';

    final colombia = results['CO'];
    if (colombia is! Map<String, dynamic>) return 'No disponible en Colombia';
    final providers = colombia['flatrate'];
    if (providers is! List || providers.isEmpty) {
      return 'No disponible en streaming';
    }

    final nombres = providers
        .whereType<Map<String, dynamic>>()
        .map((provider) => provider['provider_name'])
        .whereType<String>()
        .toSet()
        .toList();
    return nombres.isEmpty ? 'No disponible en streaming' : nombres.join(', ');
  }

  Map<String, dynamic> _decodificarRespuesta(
    http.Response response,
    String servicio,
  ) {
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw _ApiException('$servicio devolvió una respuesta inválida.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final message =
          error is Map<String, dynamic> && error['message'] is String
              ? error['message'] as String
              : 'Error HTTP ${response.statusCode}.';
      throw _ApiException('Error de $servicio: $message');
    }
    return decoded;
  }

  Future<void> _activarMicrofono() async {
    if (_escuchando) {
      await _reconocimientoVoz.stop();
      if (mounted) setState(() => _escuchando = false);
      return;
    }

    try {
      final disponible = await _reconocimientoVoz.initialize(
        onStatus: (estado) {
          if (estado == 'done' || estado == 'notListening') {
            if (mounted) setState(() => _escuchando = false);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _escuchando = false);
            _mostrarError('No se pudo reconocer la voz: ${error.errorMsg}');
          }
        },
      );

      if (!disponible) {
        _mostrarError('El reconocimiento de voz no está disponible.');
        return;
      }

      await _reconocimientoVoz.listen(
        onResult: (resultado) {
          _controladorTexto.text = resultado.recognizedWords;
          if (resultado.finalResult && mounted) {
            setState(() => _escuchando = false);
          }
        },
      );
      if (mounted) setState(() => _escuchando = true);
    } on PlatformException catch (error) {
      _mostrarError('No se pudo activar el micrófono: ${error.message}');
    } on MissingPluginException catch (error) {
      _mostrarError(
        'El plugin de micrófono no está disponible: ${error.message}',
      );
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final cantidadElementos = _mensajes.length + (_peliculas.isEmpty ? 0 : 1);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _construirEscenarioChrus(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: cantidadElementos,
                itemBuilder: (context, index) {
                  if (index < _mensajes.length) {
                    return _construirBurbuja(_mensajes[index]);
                  }
                  return _construirCarruselPeliculas();
                },
              ),
            ),
            _construirPanelEntrada(),
          ],
        ),
      ),
    );
  }

  Widget _construirEscenarioChrus() {
    final asset = _assetsAvatar[estadoChrus] ?? _assetsAvatar['neutral']!;

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Image.asset(
            'assets/logo_pelichrus.png',
            height: 42,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'PeliChrus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.asset(
                  asset,
                  key: ValueKey(estadoChrus),
                  height: 145,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy, color: Colors.cyan, size: 76),
                        Text('Chrus', style: TextStyle(color: Colors.white70)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBurbuja(_MensajeChat mensaje) {
    final alineacion =
        mensaje.esUsuario ? Alignment.centerRight : Alignment.centerLeft;
    final color = mensaje.esUsuario ? _colorBurbujaUsuario : _colorBurbujaChrus;

    return Align(
      alignment: alineacion,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: mensaje.esUsuario
              ? null
              : Border.all(color: Colors.cyan.withAlpha(89)),
        ),
        child: Text(mensaje.texto, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _construirCarruselPeliculas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            'Recomendaciones para ti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _peliculas.length,
            itemBuilder: (context, index) {
              final pelicula = _peliculas[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == _peliculas.length - 1 ? 0 : 12,
                ),
                child: TarjetaPeliculaWidget(
                  titulo: pelicula.titulo,
                  posterUrl: pelicula.posterUrl,
                  plataforma: pelicula.plataforma,
                  trailerUrl: pelicula.trailerUrl,
                  anio: pelicula.anio,
                  puntuacion: pelicula.puntuacion,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _construirPanelEntrada() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controladorTexto,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviarMensaje(),
              decoration: InputDecoration(
                hintText: '¿Qué quieres ver?',
                filled: true,
                fillColor: const Color(0xFF1E2A38),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Enviar mensaje',
            onPressed: _enviando ? null : _enviarMensaje,
            icon: const Icon(Icons.arrow_upward, color: Colors.cyan),
          ),
          FloatingActionButton(
            mini: true,
            tooltip: _escuchando ? 'Detener micrófono' : 'Hablar',
            backgroundColor: Colors.cyan,
            foregroundColor: const Color(0xFF0D1B2A),
            onPressed: _activarMicrofono,
            child: Icon(_escuchando ? Icons.mic : Icons.mic_none),
          ),
        ],
      ),
    );
  }
}

class _MensajeChat {
  const _MensajeChat({required this.texto, required this.esUsuario});

  final String texto;
  final bool esUsuario;
}

class _Pelicula {
  const _Pelicula({
    required this.titulo,
    required this.posterUrl,
    required this.plataforma,
    required this.trailerUrl,
    required this.anio,
    required this.puntuacion,
  });

  final String titulo;
  final String posterUrl;
  final String plataforma;
  final String trailerUrl;
  final String anio;
  final String puntuacion;
}

class _ApiException implements Exception {
  const _ApiException(this.message);

  final String message;
}
