import 'package:flutter/material.dart';

import '../data/repository_scope.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(repo.origen),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text('Dropbox'),
            subtitle: Text('Sin conectar · próximamente'),
          ),
          const ListTile(
            leading: Icon(Icons.mail_outline),
            title: Text('Gmail'),
            subtitle: Text('Sin conectar · próximamente'),
          ),
          const ListTile(
            leading: Icon(Icons.group_outlined),
            title: Text('Equipo'),
            subtitle: Text('Próximamente'),
          ),
        ],
      ),
    );
  }
}
