import 'package:flutter/material.dart';

import 'pantalla_principal.dart';

void main() {
  runApp(const PeliChrusApp());
}

class PeliChrusApp extends StatelessWidget {
  const PeliChrusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeliChrus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}
