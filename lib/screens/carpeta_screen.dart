import 'package:flutter/material.dart';

import '../models/obra.dart';
import '../widgets/documentos_lista.dart';
import '../widgets/subir_documento.dart';

/// Una subcarpeta dentro de la carpeta de una obra.
class CarpetaScreen extends StatelessWidget {
  const CarpetaScreen({super.key, required this.documento});

  final Documento documento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(documento.nombre)),
      body: DocumentosLista(carpeta: documento.ruta),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => subirDocumento(context, documento.ruta),
        icon: const Icon(Icons.upload),
        label: const Text('Subir'),
      ),
    );
  }
}
