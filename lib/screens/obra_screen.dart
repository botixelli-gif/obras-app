import 'package:flutter/material.dart';

import '../data/repository_scope.dart';
import '../estado.dart';
import '../models/obra.dart';
import '../widgets/correo_tile.dart';
import '../widgets/datos_builder.dart';
import '../widgets/documentos_lista.dart';
import '../widgets/formato.dart';
import '../widgets/subir_documento.dart';
import '../widgets/texto_dialog.dart';

/// Ficha de una obra: correos vinculados, documentos y notas.
class ObraScreen extends StatefulWidget {
  const ObraScreen({super.key, required this.obra});

  final Obra obra;

  @override
  State<ObraScreen> createState() => _ObraScreenState();
}

class _ObraScreenState extends State<ObraScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obra = widget.obra;
    return Scaffold(
      appBar: AppBar(
        title: Text(obra.nombre),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.mail_outline), text: 'Correos'),
            Tab(icon: Icon(Icons.folder_outlined), text: 'Documentos'),
            Tab(icon: Icon(Icons.edit_note), text: 'Notas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CorreosTab(obra: obra),
          DocumentosLista(carpeta: obra.carpetaDropbox),
          _NotasTab(obra: obra),
        ],
      ),
      floatingActionButton: switch (_tabs.index) {
        1 => FloatingActionButton.extended(
          onPressed: () => subirDocumento(context, obra.carpetaDropbox),
          icon: const Icon(Icons.upload),
          label: const Text('Subir'),
        ),
        2 => FloatingActionButton.extended(
          onPressed: () => _nuevaNota(context, obra),
          icon: const Icon(Icons.add),
          label: const Text('Nueva nota'),
        ),
        _ => null,
      },
    );
  }

  Future<void> _nuevaNota(BuildContext context, Obra obra) async {
    final estado = EstadoScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nombre = estado.nombre.isEmpty ? await pedirNombre(context) : null;
    if (nombre != null) await estado.cambiarNombre(nombre);
    if (!context.mounted) return;

    final texto = await pedirTexto(
      context,
      titulo: 'Nueva nota',
      pista: 'Qué ha pasado o qué ha cambiado en la obra',
      lineas: 3,
      mayusculas: TextCapitalization.sentences,
    );
    if (texto == null || texto.trim().isEmpty || !context.mounted) return;
    try {
      await RepositoryScope.read(context).registrarNota(obra, texto.trim());
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo guardar la nota: $e')),
      );
    }
  }
}

/// Pide el nombre de la persona para firmar sus notas. Null si cancela.
Future<String?> pedirNombre(BuildContext context, {String inicial = ''}) =>
    pedirTexto(
      context,
      titulo: '¿Cómo te llamas?',
      inicial: inicial,
      ayuda: 'Aparecerá en las notas que escribas',
      mayusculas: TextCapitalization.words,
    );

class _CorreosTab extends StatelessWidget {
  const _CorreosTab({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    return DatosBuilder<List<Correo>>(
      cargar: (repo) => repo.correos(obra),
      builder: (context, correos) => correos.isEmpty
          ? listaVacia(
              Icons.mail_outline,
              'Sin correos vinculados.\nAsígnalos desde "Sin asignar".',
            )
          : ListView.separated(
              itemCount: correos.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => CorreoTile(correo: correos[i]),
            ),
    );
  }
}

class _NotasTab extends StatelessWidget {
  const _NotasTab({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    return DatosBuilder<List<Nota>>(
      cargar: (repo) => repo.notas(obra),
      builder: (context, notas) => notas.isEmpty
          ? listaVacia(Icons.edit_note, 'Aún no hay notas.')
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: notas.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = notas[i];
                return ListTile(
                  title: Text(n.texto),
                  subtitle: Text('${n.autor} · ${formatoFechaHora(n.fecha)}'),
                );
              },
            ),
    );
  }
}
