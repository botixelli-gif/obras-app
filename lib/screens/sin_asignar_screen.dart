import 'package:flutter/material.dart';

import '../data/repository_scope.dart';
import '../models/obra.dart';
import '../widgets/correo_tile.dart';
import '../widgets/datos_builder.dart';

/// Correos que todavía no están vinculados a ninguna obra.
class SinAsignarScreen extends StatelessWidget {
  const SinAsignarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = RepositoryScope.of(context).demo;
    return Scaffold(
      appBar: AppBar(title: const Text('Sin asignar')),
      body: DatosBuilder<List<Correo>>(
        cargar: (repo) => repo.sinAsignar(),
        builder: (context, correos) => correos.isEmpty
            ? listaVacia(
                Icons.mark_email_read_outlined,
                demo ? 'Todo asignado' : 'La conexión con Gmail llega pronto.',
              )
            : ListView.separated(
                itemCount: correos.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => CorreoTile(
                  correo: correos[i],
                  trailing: IconButton(
                    tooltip: 'Asignar a obra',
                    icon: const Icon(Icons.drive_file_move_outline),
                    onPressed: () => _asignar(context, correos[i]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _asignar(BuildContext context, Correo correo) async {
    final repo = RepositoryScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final obras = await repo.obras();
    if (!context.mounted) return;
    final obra = await showDialog<Obra>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Asignar a obra'),
        children: [
          for (final o in obras)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, o),
              child: Text(o.nombre),
            ),
        ],
      ),
    );
    if (obra == null) return;
    await repo.vincularCorreo(correo, obra);
    messenger.showSnackBar(
      SnackBar(content: Text('Vinculado a ${obra.nombre}')),
    );
  }
}
