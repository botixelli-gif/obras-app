import 'package:flutter/material.dart';

import '../estado.dart';
import '../widgets/texto_dialog.dart';
import 'obra_screen.dart' show pedirNombre;

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = EstadoScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Tu nombre'),
            subtitle: Text(
              estado.nombre.isEmpty ? 'Sin indicar' : estado.nombre,
            ),
            onTap: () async {
              final nombre = await pedirNombre(context, inicial: estado.nombre);
              if (nombre != null) await estado.cambiarNombre(nombre);
            },
          ),
          const Divider(),
          _Dropbox(estado: estado),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Carpeta de obras en Dropbox'),
            subtitle: Text(
              estado.carpetaRaiz.isEmpty ? '/' : estado.carpetaRaiz,
            ),
            onTap: () => _cambiarCarpeta(context, estado),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.mail_outline),
            title: Text('Gmail'),
            subtitle: Text('Próximamente'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Datos'),
            subtitle: Text(estado.repository.origen),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarCarpeta(BuildContext context, Estado estado) async {
    final carpeta = await pedirTexto(
      context,
      titulo: 'Carpeta de obras',
      inicial: estado.carpetaRaiz,
      pista: '/Obras',
      ayuda: 'Cada subcarpeta será una obra',
    );
    if (carpeta != null) await estado.cambiarCarpeta(carpeta);
  }
}

class _Dropbox extends StatefulWidget {
  const _Dropbox({required this.estado});

  final Estado estado;

  @override
  State<_Dropbox> createState() => _DropboxState();
}

class _DropboxState extends State<_Dropbox> {
  bool _ocupado = false;

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    if (!estado.dropboxDisponible) {
      return const ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: Text('Dropbox'),
        subtitle: Text(
          'Esta versión de la app aún no tiene la clave de '
          'Dropbox',
        ),
      );
    }
    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: const Text('Dropbox'),
      subtitle: Text(estado.dropboxConectado ? 'Conectado' : 'Sin conectar'),
      trailing: _ocupado
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : estado.dropboxConectado
          ? TextButton(
              onPressed: () => _hacer(estado.desconectarDropbox),
              child: const Text('Desconectar'),
            )
          : FilledButton(
              onPressed: () => _hacer(estado.conectarDropbox),
              child: const Text('Conectar'),
            ),
    );
  }

  Future<void> _hacer(Future<void> Function() accion) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ocupado = true);
    try {
      await accion();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }
}
