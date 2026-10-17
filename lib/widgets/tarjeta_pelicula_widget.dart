import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class TarjetaPeliculaWidget extends StatelessWidget {
  const TarjetaPeliculaWidget({
    super.key,
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

  Future<void> _abrirUrl(BuildContext context, Uri uri) async {
    try {
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!abierto && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
        );
      }
    } on PlatformException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el enlace: ${error.message}')),
        );
      }
    }
  }

  void _abrirTrailer(BuildContext context) {
    _abrirUrl(context, Uri.parse(trailerUrl));
  }

  void _contactarPorWhatsApp(BuildContext context) {
    final mensaje = "¡Hola! Quiero ver '$titulo' en PeliChrus. "
        'Vi que está disponible en $plataforma. ¿Me ayudas?';
    final uri = Uri.parse(
      'https://wa.me/573052936246?text=${Uri.encodeComponent(mensaje)}',
    );
    _abrirUrl(context, uri);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFF1E2A38),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFF263442),
                      child: Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: Colors.white54,
                          size: 42,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$anio • ⭐ $puntuacion',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    plataforma,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.cyan, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirTrailer(context),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Tráiler'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.cyan,
                        side: const BorderSide(color: Colors.cyan),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _contactarPorWhatsApp(context),
                      icon: const Icon(Icons.chat, size: 15),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
