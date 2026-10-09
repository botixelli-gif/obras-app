import 'package:flutter/material.dart';

import '../data/repository_scope.dart';
import '../models/obra.dart';
import '../widgets/correo_tile.dart';

/// Correos que todavía no están vinculados a ninguna obra.
class SinAsignarScreen extends StatelessWidget {
  const SinAsignarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final correos = RepositoryScope.of(context).sinAsignar;
    return Scaffold(
      appBar: AppBar(title: const Text('Sin asignar')),
      body: correos.isEmpty
          ? const Center(child: Text('Todo asignado'))
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
    );
  }

  Future<void> _asignar(BuildContext context, Correo correo) async {
    final repo = RepositoryScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final obra = await showDialog<Obra>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Asignar a obra'),
        children: [
          for (final o in repo.obras)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, o),
              child: Text(o.nombre),
            ),
        ],
      ),
    );
    if (obra == null) return;
    await repo.vincularCorreo(correo.id, obra.id);
    messenger.showSnackBar(
      SnackBar(content: Text('Vinculado a ${obra.nombre}')),
    );
  }
}
