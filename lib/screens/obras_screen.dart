import 'package:flutter/material.dart';

import '../data/repository_scope.dart';
import '../models/obra.dart';
import '../widgets/datos_builder.dart';
import 'obra_screen.dart';

class ObrasScreen extends StatelessWidget {
  const ObrasScreen({super.key, required this.irAAjustes});

  final VoidCallback irAAjustes;

  @override
  Widget build(BuildContext context) {
    final demo = RepositoryScope.of(context).demo;
    return Scaffold(
      appBar: AppBar(title: const Text('Obras')),
      body: Column(
        children: [
          if (demo)
            MaterialBanner(
              content: const Text(
                'Estás viendo datos de ejemplo. Conecta Dropbox para ver '
                'vuestras obras.',
              ),
              leading: const Icon(Icons.info_outline),
              actions: [
                TextButton(onPressed: irAAjustes, child: const Text('Ajustes')),
              ],
            ),
          Expanded(
            child: DatosBuilder<List<Obra>>(
              cargar: (repo) => repo.obras(),
              builder: (context, obras) => obras.isEmpty
                  ? listaVacia(
                      Icons.apartment,
                      'No hay obras.\nCada subcarpeta de la carpeta de obras '
                      'en Dropbox aparece aquí.',
                    )
                  : ListView.separated(
                      itemCount: obras.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final obra = obras[i];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.apartment),
                          ),
                          title: Text(obra.nombre),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ObraScreen(obra: obra),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
