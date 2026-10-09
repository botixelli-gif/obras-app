import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/obras_repository.dart';
import 'data/repository_scope.dart';
import 'screens/home_screen.dart';

class ObrasApp extends StatelessWidget {
  const ObrasApp({super.key, required this.repository});

  final ObrasRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: repository,
      child: MaterialApp(
        title: 'Obras',
        debugShowCheckedModeBanner: false,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFE07A1F),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFFE07A1F),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
