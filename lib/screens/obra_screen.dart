import 'package:flutter/material.dart';

import '../data/repository_scope.dart';
import '../models/obra.dart';
import '../widgets/correo_tile.dart';
import '../widgets/formato.dart';
import '../widgets/subir_documento.dart';

/// Ficha de una obra: correos vinculados, documentos y registro de cambios.
class ObraScreen extends StatefulWidget {
  const ObraScreen({super.key, required this.obraId});

  final String obraId;

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
    final obra = RepositoryScope.of(context).obra(widget.obraId);
    if (obra == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Esta obra ya no existe')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(obra.nombre),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.mail_outline), text: 'Correos'),
            Tab(icon: Icon(Icons.folder_outlined), text: 'Documentos'),
            Tab(icon: Icon(Icons.edit_note), text: 'Cambios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CorreosTab(obra: obra),
          _DocumentosTab(obra: obra),
          _CambiosTab(obra: obra),
        ],
      ),
      floatingActionButton: switch (_tabs.index) {
        1 => FloatingActionButton.extended(
            onPressed: () => subirDocumento(context, obra.id),
            icon: const Icon(Icons.upload),
            label: const Text('Subir'),
          ),
        2 => FloatingActionButton.extended(
            onPressed: () => _nuevoCambio(context, obra),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo cambio'),
          ),
        _ => null,
      },
    );
  }

  Future<void> _nuevoCambio(BuildContext context, Obra obra) async {
    final repo = RepositoryScope.of(context);
    final texto = await showDialog<String>(
      context: context,
      builder: (context) => const _NuevoCambioDialog(),
    );
    if (texto == null || texto.trim().isEmpty) return;
    await repo.registrarCambio(obra.id, texto.trim());
  }
}

class _CorreosTab extends StatelessWidget {
  const _CorreosTab({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final correos = RepositoryScope.of(context).correos(obra.id);
    if (correos.isEmpty) {
      return const _Vacio(
        icono: Icons.mail_outline,
        texto: 'Sin correos vinculados.\n'
            'Asígnalos desde "Sin asignar".',
      );
    }
    return ListView.separated(
      itemCount: correos.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => CorreoTile(correo: correos[i]),
    );
  }
}

class _DocumentosTab extends StatefulWidget {
  const _DocumentosTab({required this.obra});

  final Obra obra;

  @override
  State<_DocumentosTab> createState() => _DocumentosTabState();
}

class _DocumentosTabState extends State<_DocumentosTab> {
  late Future<List<Documento>> _docs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se llama al abrir la pestaña y cada vez que el repositorio avisa de
    // cambios (por ejemplo, tras subir un documento).
    _docs = RepositoryScope.of(context).documentos(widget.obra.id);
  }

  @override
  Widget build(BuildContext context) {
    final obra = widget.obra;
    return FutureBuilder<List<Documento>>(
      future: _docs,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Vacio(
            icono: Icons.error_outline,
            texto: 'No se pudieron cargar los documentos.\n${snapshot.error}',
          );
        }
        final docs = snapshot.data;
        if (docs == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (docs.isEmpty) {
          return const _Vacio(
            icono: Icons.folder_open,
            texto: 'La carpeta está vacía.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: docs.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i == 0) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_outlined),
                title: Text('Dropbox: ${obra.carpetaDropbox}'),
              );
            }
            final d = docs[i - 1];
            return ListTile(
              leading: Icon(d.esCarpeta
                  ? Icons.folder
                  : Icons.insert_drive_file_outlined),
              title: Text(d.nombre),
              subtitle: Text(d.esCarpeta
                  ? formatoFecha(d.modificado)
                  : '${formatoFecha(d.modificado)} · '
                      '${formatoTamano(d.bytes)}'),
            );
          },
        );
      },
    );
  }
}

class _CambiosTab extends StatelessWidget {
  const _CambiosTab({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final cambios = RepositoryScope.of(context).cambios(obra.id);
    if (cambios.isEmpty) {
      return const _Vacio(
        icono: Icons.edit_note,
        texto: 'Aún no hay cambios registrados.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: cambios.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = cambios[i];
        return ListTile(
          title: Text(c.texto),
          subtitle: Text('${c.autor} · ${formatoFechaHora(c.fecha)}'),
        );
      },
    );
  }
}

class _NuevoCambioDialog extends StatefulWidget {
  const _NuevoCambioDialog();

  @override
  State<_NuevoCambioDialog> createState() => _NuevoCambioDialogState();
}

class _NuevoCambioDialogState extends State<_NuevoCambioDialog> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo cambio'),
      content: TextField(
        controller: _texto,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Qué ha cambiado en la obra',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _texto.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
