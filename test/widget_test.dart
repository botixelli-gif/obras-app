import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obras_app/app.dart';
import 'package:obras_app/estado.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Estado> estadoDemo({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  return Estado.cargar(prefs: await SharedPreferences.getInstance());
}

void main() {
  testWidgets('muestra las obras de ejemplo y abre la ficha', (tester) async {
    await tester.pumpWidget(ObrasApp(estado: await estadoDemo()));
    await tester.pumpAndSettle();

    expect(find.textContaining('datos de ejemplo'), findsOneWidget);
    expect(find.text('Calle Mayor 12'), findsOneWidget);
    expect(find.text('Nave Polígono Sur'), findsOneWidget);

    await tester.tap(find.text('Calle Mayor 12'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuesto revisado Calle Mayor 12'), findsOneWidget);

    await tester.tap(find.text('Documentos'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuesto v3.pdf'), findsOneWidget);

    await tester.tap(find.text('Planos'));
    await tester.pumpAndSettle();
    expect(find.text('Planta baja.pdf'), findsOneWidget);
  });

  testWidgets('asignar un correo lo lleva a la obra', (tester) async {
    final estado = await estadoDemo();
    await tester.pumpWidget(ObrasApp(estado: estado));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sin asignar').last);
    await tester.pumpAndSettle();
    expect(find.text('Pedido de ferralla para la nave'), findsOneWidget);

    await tester.tap(find.byTooltip('Asignar a obra').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(SimpleDialogOption, 'Nave Polígono Sur'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pedido de ferralla para la nave'), findsNothing);

    final repo = estado.repository;
    final nave = (await repo.obras()).firstWhere((o) => o.id == 'nave-sur');
    expect((await repo.correos(nave)).map((c) => c.id), contains('m2'));
  });

  testWidgets('la primera nota pide el nombre y lo usa como autor', (
    tester,
  ) async {
    final estado = await estadoDemo();
    await tester.pumpWidget(ObrasApp(estado: estado));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nave Polígono Sur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notas'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay notas.'), findsOneWidget);

    await tester.tap(find.text('Nueva nota'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lucía');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hormigonado de zapatas');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(estado.nombre, 'Lucía');
    expect(find.text('Hormigonado de zapatas'), findsOneWidget);
    expect(find.textContaining('Lucía ·'), findsOneWidget);
  });
}
