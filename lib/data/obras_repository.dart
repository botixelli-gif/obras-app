import 'package:flutter/foundation.dart';

import '../models/obra.dart';

/// Punto único de acceso a los datos de las obras.
///
/// Hoy lo implementa [DemoRepository] con datos de ejemplo. Después lo
/// implementarán Dropbox (documentos), Firebase (cambios y correos vinculados)
/// y Gmail (bandeja sin asignar), sin tocar las pantallas.
abstract class ObrasRepository extends ChangeNotifier {
  /// Texto que se muestra en Ajustes para saber de dónde salen los datos.
  String get origen;

  List<Obra> get obras;
  Obra? obra(String id);

  Future<List<Documento>> documentos(String obraId);
  Future<void> subirDocumento(String obraId, String nombre, Uint8List contenido);

  List<Cambio> cambios(String obraId);
  Future<void> registrarCambio(String obraId, String texto);

  List<Correo> correos(String obraId);
  List<Correo> get sinAsignar;
  Future<void> vincularCorreo(String correoId, String obraId);
}
