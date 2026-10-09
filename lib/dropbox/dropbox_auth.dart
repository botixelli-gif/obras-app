import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

/// Guarda los tokens fuera del alcance de otras apps (Keychain en iPhone,
/// Keystore en Android). Se abstrae para poder probarlo.
abstract class TokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Abre el navegador del sistema para iniciar sesión y devuelve la URL a la
/// que Dropbox redirige al terminar.
typedef WebAuthenticator = Future<String> Function(
  Uri url,
  String callbackScheme,
);

Future<String> _flutterWebAuth(Uri url, String callbackScheme) =>
    FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
    );

/// Inicio de sesión en Dropbox con OAuth 2 + PKCE (sin secreto en la app).
///
/// Se pide acceso "offline": Dropbox entrega un refresh token que no caduca,
/// así que cada móvil inicia sesión una sola vez.
class DropboxAuth {
  DropboxAuth({
    required this.appKey,
    http.Client? client,
    this._store = const SecureTokenStore(),
    this._authenticate = _flutterWebAuth,
    this._now = DateTime.now,
  }) : _client = client ?? http.Client();

  final String appKey;
  final http.Client _client;
  final TokenStore _store;
  final WebAuthenticator _authenticate;
  final DateTime Function() _now;

  static const callbackScheme = 'obrasapp';
  static const redirectUri = '$callbackScheme://dropbox';
  static final _tokenUrl = Uri.https('api.dropboxapi.com', '/oauth2/token');

  static const _kRefresh = 'dropbox_refresh_token';
  static const _kAccess = 'dropbox_access_token';
  static const _kExpires = 'dropbox_access_expires';

  String? _accessToken;
  DateTime? _expires;

  Future<bool> get conectado async => await _store.read(_kRefresh) != null;

  Future<void> conectar() async {
    final verifier = _codeVerifier();
    final challenge = base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final authorize = Uri.https('www.dropbox.com', '/oauth2/authorize', {
      'client_id': appKey,
      'response_type': 'code',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'token_access_type': 'offline',
      'redirect_uri': redirectUri,
    });

    final result = Uri.parse(await _authenticate(authorize, callbackScheme));
    final code = result.queryParameters['code'];
    if (code == null) {
      final error =
          result.queryParameters['error_description'] ??
          result.queryParameters['error'] ??
          'sin código';
      throw StateError('Dropbox no autorizó el acceso: $error');
    }

    final json = await _token({
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': appKey,
      'code_verifier': verifier,
      'redirect_uri': redirectUri,
    });
    await _store.write(_kRefresh, json['refresh_token'] as String);
    await _guardarAcceso(json);
  }

  Future<void> desconectar() async {
    _accessToken = null;
    _expires = null;
    await _store.delete(_kRefresh);
    await _store.delete(_kAccess);
    await _store.delete(_kExpires);
  }

  /// Token de acceso válido; lo renueva si ha caducado o si [forceRefresh].
  Future<String> accessToken({bool forceRefresh = false}) async {
    if (_accessToken == null) {
      _accessToken = await _store.read(_kAccess);
      final expires = await _store.read(_kExpires);
      _expires = expires == null ? null : DateTime.tryParse(expires);
    }
    final vigente =
        _accessToken != null &&
        _expires != null &&
        _now().isBefore(_expires!.subtract(const Duration(minutes: 5)));
    if (vigente && !forceRefresh) return _accessToken!;

    final refresh = await _store.read(_kRefresh);
    if (refresh == null) throw StateError('Dropbox no está conectado');
    await _guardarAcceso(
      await _token({
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
        'client_id': appKey,
      }),
    );
    return _accessToken!;
  }

  Future<Map<String, dynamic>> _token(Map<String, String> body) async {
    final response = await _client.post(_tokenUrl, body: body);
    if (response.statusCode != 200) {
      throw StateError(
        'Dropbox rechazó el inicio de sesión (${response.statusCode}): '
        '${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _guardarAcceso(Map<String, dynamic> json) async {
    _accessToken = json['access_token'] as String;
    _expires = _now().add(Duration(seconds: json['expires_in'] as int));
    await _store.write(_kAccess, _accessToken!);
    await _store.write(_kExpires, _expires!.toIso8601String());
  }

  static String _codeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
