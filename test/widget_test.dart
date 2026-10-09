import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obras_app/app.dart';
import 'package:obras_app/data/demo_repository.dart';

void main() {
  testWidgets('muestra las obras y abre la ficha', (tester) async {
    await tester.pumpWidget(ObrasApp(repository: DemoRepository()));

    expect(find.text('Calle Mayor 12'), findsOneWidget);
    expect(find.text('Nave Polígono Sur'), findsOneWidget);

    await tester.tap(find.text('Calle Mayor 12'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuesto revisado Calle Mayor 12'), findsOneWidget);

    await tester.tap(find.text('Documentos'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuesto v3.pdf'), findsOneWidget);
  });

  testWidgets('asignar un correo lo quita de "Sin asignar"', (tester) async {
    final repo = DemoRepository();
    await tester.pumpWidget(ObrasApp(repository: repo));

    await tester.tap(find.text('Sin asignar'));
    await tester.pumpAndSettle();
    expect(find.text('Pedido de ferralla para la nave'), findsOneWidget);

    await tester.tap(find.byTooltip('Asignar a obra').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SimpleDialogOption, 'Nave Polígono Sur'));
    await tester.pumpAndSettle();

    expect(repo.sinAsignar.map((c) => c.id), isNot(contains('m2')));
    expect(repo.correos('nave-sur').map((c) => c.id), contains('m2'));
  });

  testWidgets('registrar un cambio lo añade a la obra', (tester) async {
    final repo = DemoRepository();
    await tester.pumpWidget(ObrasApp(repository: repo));

    await tester.tap(find.text('Nave Polígono Sur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo cambio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hormigonado de zapatas');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Hormigonado de zapatas'), findsOneWidget);
    expect(repo.cambios('nave-sur'), hasLength(1));
  });
}
