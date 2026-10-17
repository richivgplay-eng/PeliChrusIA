import 'package:flutter_test/flutter_test.dart';
import 'package:pelichrus/main.dart';

void main() {
  testWidgets('muestra la pantalla principal de PeliChrus', (tester) async {
    await tester.pumpWidget(const PeliChrusApp());
    await tester.pump();

    expect(find.text('PeliChrus'), findsOneWidget);
    expect(find.text('¿Qué quieres ver?'), findsOneWidget);
    expect(find.byTooltip('Enviar mensaje'), findsOneWidget);
    expect(find.byTooltip('Hablar'), findsOneWidget);
  });
}
