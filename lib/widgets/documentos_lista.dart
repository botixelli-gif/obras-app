import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repository_scope.dart';
import '../models/obra.dart';
import '../screens/carpeta_screen.dart';
import 'datos_builder.dart';
import 'formato.dart';

/// Contenido de una carpeta de Dropbox. Las subcarpetas se abren en otra
/// pantalla y los archivos en la app que corresponda del móvil.
class DocumentosLista extends StatelessWidget {
  const DocumentosLista({super.key, required this.carpeta});

  final String carpeta;

  @override
  Widget build(BuildContext context) {
    return DatosBuilder<List<Documento>>(
      cargar: (repo) => repo.carpeta(carpeta),
      builder: (context, docs) {
        if (docs.isEmpty) {
          return listaVacia(Icons.folder_open, 'La carpeta está vacía.');
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = docs[i];
            return ListTile(
              leading: Icon(d.esCarpeta ? Icons.folder : _icono(d.nombre)),
              title: Text(d.nombre),
              subtitle: Text(
                d.esCarpeta
                    ? formatoFecha(d.modificado)
                    : '${formatoFecha(d.modificado)} · '
                          '${formatoTamano(d.bytes)}',
              ),
              trailing: d.esCarpeta ? const Icon(Icons.chevron_right) : null,
              onTap: () => d.esCarpeta
                  ? Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CarpetaScreen(documento: d),
                      ),
                    )
                  : _abrir(context, d),
            );
          },
        );
      },
    );
  }

  Future<void> _abrir(BuildContext context, Documento d) async {
    final repo = RepositoryScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final enlace = await repo.enlace(d);
      final abierto = await launchUrl(
        enlace,
        mode: LaunchMode.externalApplication,
      );
      if (!abierto) throw StateError('ninguna app puede abrirlo');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo abrir ${d.nombre}: $e')),
      );
    }
  }

  static IconData _icono(String nombre) {
    final n = nombre.toLowerCase();
    if (n.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (RegExp(r'\.(jpe?g|png|heic|webp)$').hasMatch(n)) {
      return Icons.image_outlined;
    }
    if (RegExp(r'\.(xlsx?|csv|ods)$').hasMatch(n)) {
      return Icons.table_chart_outlined;
    }
    if (RegExp(r'\.(dwg|dxf)$').hasMatch(n)) return Icons.architecture;
    return Icons.insert_drive_file_outlined;
  }
}
