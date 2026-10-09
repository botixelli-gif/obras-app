import 'package:flutter/foundation.dart';

import '../models/obra.dart';

/// Obras, documentos y notas. Hoy: Dropbox o datos de ejemplo.
abstract class ObrasStore {
  Future<List<Obra>> obras();

  /// Contenido de una carpeta (la de la obra o una subcarpeta suya).
  Future<List<Documento>> carpeta(String ruta);
  Future<void> subir(String carpeta, String nombre, Uint8List contenido);

  /// Enlace para abrir el documento fuera de la app.
  Future<Uri> enlace(Documento documento);

  Future<List<Nota>> notas(Obra obra);
  Future<void> registrarNota(Obra obra, String texto, String autor);
}

/// Correos y su vínculo con las obras. Hoy: datos de ejemplo o ninguno;
/// después, Gmail.
abstract class CorreosStore {
  Future<List<Correo>> correos(Obra obra);
  Future<List<Correo>> sinAsignar();
  Future<void> vincular(Correo correo, Obra obra);
}

/// Mientras Gmail no esté conectado.
class SinCorreos implements CorreosStore {
  const SinCorreos();

  @override
  Future<List<Correo>> correos(Obra obra) async => const [];

  @override
  Future<List<Correo>> sinAsignar() async => const [];

  @override
  Future<void> vincular(Correo correo, Obra obra) async {}
}
