import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/repository_scope.dart';
import 'estado.dart';
import 'screens/home_screen.dart';

class ObrasApp extends StatelessWidget {
  const ObrasApp({super.key, required this.estado});

  final Estado estado;

  @override
  Widget build(BuildContext context) {
    return EstadoScope(
      estado: estado,
      child: ListenableBuilder(
        listenable: estado,
        builder: (context, child) =>
            RepositoryScope(repository: estado.repository, child: child!),
        child: MaterialApp(
          title: 'Obras',
          debugShowCheckedModeBanner: false,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(colorSchemeSeed: const Color(0xFFE07A1F)),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFFE07A1F),
            brightness: Brightness.dark,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
