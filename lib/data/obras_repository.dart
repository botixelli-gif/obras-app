import 'package:flutter/foundation.dart';

import '../models/obra.dart';
import 'stores.dart';

/// Punto único de acceso a los datos para las pantallas.
///
/// Junta el origen de las obras y documentos (Dropbox o ejemplo) con el de
/// los correos (Gmail o ejemplo), y avisa a las pantallas cuando algo cambia
/// para que vuelvan a cargar.
class ObrasRepository extends ChangeNotifier {
  ObrasRepository({
    required this.origen,
    required this._obras,
    this._correos = const SinCorreos(),
    this.autor = '',
    this.demo = false,
  });

  /// Texto para Ajustes: de dónde salen los datos.
  final String origen;

  /// Nombre de quien usa este móvil, para firmar las notas.
  final String autor;

  /// Son datos de ejemplo, no los de la empresa.
  final bool demo;

  final ObrasStore _obras;
  final CorreosStore _correos;

  Future<List<Obra>> obras() => _obras.obras();

  Future<List<Documento>> carpeta(String ruta) => _obras.carpeta(ruta);

  Future<void> subir(String carpeta, String nombre, Uint8List contenido) =>
      _cambia(_obras.subir(carpeta, nombre, contenido));

  Future<Uri> enlace(Documento documento) => _obras.enlace(documento);

  Future<List<Nota>> notas(Obra obra) => _obras.notas(obra);

  Future<void> registrarNota(Obra obra, String texto) =>
      _cambia(_obras.registrarNota(obra, texto, autor));

  Future<List<Correo>> correos(Obra obra) => _correos.correos(obra);

  Future<List<Correo>> sinAsignar() => _correos.sinAsignar();

  Future<void> vincularCorreo(Correo correo, Obra obra) =>
      _cambia(_correos.vincular(correo, obra));

  /// Avisa también si falla: puede que la operación se hiciera a medias.
  Future<void> _cambia(Future<void> operacion) async {
    try {
      await operacion;
    } finally {
      notifyListeners();
    }
  }

  /// Fuerza que todas las pantallas recarguen (al tirar hacia abajo).
  void recargar() => notifyListeners();
}
