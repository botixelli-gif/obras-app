import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'dropbox/dropbox_auth.dart';
import 'estado.dart';

/// Clave pública (App key) de la app "Obras" en Dropbox. No es secreta: la
/// seguridad la da el inicio de sesión con PKCE. Se puede cambiar al compilar
/// con `--dart-define=DROPBOX_APP_KEY=...`.
const dropboxAppKey = String.fromEnvironment(
  'DROPBOX_APP_KEY',
  defaultValue: '4ekvldj345i5q18',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final estado = await Estado.cargar(
    prefs: await SharedPreferences.getInstance(),
    dropbox: dropboxAppKey.isEmpty ? null : DropboxAuth(appKey: dropboxAppKey),
  );
  runApp(ObrasApp(estado: estado));
}
