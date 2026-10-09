import 'package:flutter/material.dart';

import '../data/repository_scope.dart';
import 'obra_screen.dart';

class ObrasScreen extends StatelessWidget {
  const ObrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final obras = repo.obras;
    return Scaffold(
      appBar: AppBar(title: const Text('Obras')),
      body: obras.isEmpty
          ? const Center(child: Text('No hay obras todavía'))
          : ListView.separated(
              itemCount: obras.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final obra = obras[i];
                final cambios = repo.cambios(obra.id).length;
                final correos = repo.correos(obra.id).length;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.apartment)),
                  title: Text(obra.nombre),
                  subtitle: Text(
                    [
                      if (obra.direccion != null) obra.direccion!,
                      '$correos correos · $cambios cambios',
                    ].join('\n'),
                  ),
                  isThreeLine: obra.direccion != null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ObraScreen(obraId: obra.id),
                  )),
                );
              },
            ),
    );
  }
}
