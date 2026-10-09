import 'package:flutter/material.dart';

import '../data/repository_scope.dart';
import 'ajustes_screen.dart';
import 'obras_screen.dart';
import 'sin_asignar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _seccion = 0;

  @override
  Widget build(BuildContext context) {
    final pendientes = RepositoryScope.of(context).sinAsignar.length;
    return Scaffold(
      body: IndexedStack(
        index: _seccion,
        children: const [ObrasScreen(), SinAsignarScreen(), AjustesScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seccion,
        onDestinationSelected: (i) => setState(() => _seccion = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Obras',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendientes > 0,
              label: Text('$pendientes'),
              child: const Icon(Icons.mark_email_unread_outlined),
            ),
            selectedIcon: const Icon(Icons.mark_email_unread),
            label: 'Sin asignar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
