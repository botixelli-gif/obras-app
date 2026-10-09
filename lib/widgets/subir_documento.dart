import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repository_scope.dart';
import 'formato.dart';

/// Pregunta si subir una foto o un archivo y lo sube a la carpeta de la obra.
Future<void> subirDocumento(BuildContext context, String obraId) async {
  final repo = RepositoryScope.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final origen = await showModalBottomSheet<_Origen>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Hacer una foto'),
            onTap: () => Navigator.pop(context, _Origen.camara),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, _Origen.galeria),
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Elegir un archivo'),
            onTap: () => Navigator.pop(context, _Origen.archivo),
          ),
        ],
      ),
    ),
  );
  if (origen == null) return;

  final XFile? archivo;
  final String nombre;
  switch (origen) {
    case _Origen.camara:
    case _Origen.galeria:
      archivo = await ImagePicker().pickImage(
        source:
            origen == _Origen.camara ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      nombre = 'Foto ${_marcaTiempo(DateTime.now())}.jpg';
    case _Origen.archivo:
      final elegido = await FilePicker.pickFile();
      archivo = elegido?.xFile;
      nombre = elegido?.name ?? '';
  }
  if (archivo == null) return;

  try {
    await repo.subirDocumento(obraId, nombre, await archivo.readAsBytes());
    messenger.showSnackBar(SnackBar(content: Text('Subido: $nombre')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('No se pudo subir: $e')));
  }
}

enum _Origen { camara, galeria, archivo }

String _marcaTiempo(DateTime f) =>
    '${f.year}-${dosDigitos(f.month)}-${dosDigitos(f.day)} '
    '${dosDigitos(f.hour)}.${dosDigitos(f.minute)}.${dosDigitos(f.second)}';
