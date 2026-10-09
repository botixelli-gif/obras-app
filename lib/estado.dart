import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/demo_store.dart';
import 'data/obras_repository.dart';
import 'dropbox/dropbox_api.dart';
import 'dropbox/dropbox_auth.dart';
import 'dropbox/dropbox_store.dart';

/// Ajustes de este móvil y conexión con las cuentas. Decide de dónde salen
/// los datos: de Dropbox si está conectado, si no, de ejemplo.
class Estado extends ChangeNotifier {
  Estado._(this._prefs, this._auth, this._dropboxConectado) {
    _reconstruir();
  }

  static Future<Estado> cargar({
    required SharedPreferences prefs,
    DropboxAuth? dropbox,
  }) async {
    final conectado = dropbox != null && await dropbox.conectado;
    return Estado._(prefs, dropbox, conectado);
  }

  final SharedPreferences _prefs;
  final DropboxAuth? _auth;
  bool _dropboxConectado;
  late ObrasRepository _repository;

  /// Se conserva entre reconstrucciones para no perder lo que se pruebe.
  late final DemoStore _demo = DemoStore();

  static const _kNombre = 'nombre';
  static const _kCarpeta = 'carpeta_raiz';
  static const carpetaPorDefecto = '/Obras';

  ObrasRepository get repository => _repository;

  String get nombre => _prefs.getString(_kNombre) ?? '';
  String get carpetaRaiz => _prefs.getString(_kCarpeta) ?? carpetaPorDefecto;

  /// Esta versión de la app lleva la clave de Dropbox.
  bool get dropboxDisponible => _auth != null;
  bool get dropboxConectado => _dropboxConectado;

  Future<void> cambiarNombre(String nombre) async {
    await _prefs.setString(_kNombre, nombre.trim());
    _reconstruir();
  }

  Future<void> cambiarCarpeta(String carpeta) async {
    await _prefs.setString(_kCarpeta, normalizarRuta(carpeta));
    _reconstruir();
  }

  Future<void> conectarDropbox() async {
    await _auth!.conectar();
    _dropboxConectado = true;
    _reconstruir();
  }

  Future<void> desconectarDropbox() async {
    await _auth!.desconectar();
    _dropboxConectado = false;
    _reconstruir();
  }

  void _reconstruir() {
    if (_dropboxConectado) {
      _repository = ObrasRepository(
        origen: 'Dropbox · $carpetaRaiz',
        obras: DropboxStore(DropboxApi(_auth!.accessToken), carpetaRaiz),
        autor: nombre,
      );
    } else {
      _repository = ObrasRepository(
        origen: 'Datos de ejemplo',
        obras: _demo,
        correos: _demo,
        autor: nombre,
        demo: true,
      );
    }
    notifyListeners();
  }
}

class EstadoScope extends InheritedNotifier<Estado> {
  const EstadoScope({super.key, required Estado estado, required super.child})
    : super(notifier: estado);

  static Estado of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EstadoScope>()!.notifier!;
}
