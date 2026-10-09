import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Un archivo o carpeta de Dropbox.
class DropboxEntry {
  const DropboxEntry({
    required this.name,
    required this.pathDisplay,
    required this.pathLower,
    required this.isFolder,
    this.serverModified,
    this.size = 0,
  });

  factory DropboxEntry.fromJson(Map<String, dynamic> json) => DropboxEntry(
    name: json['name'] as String,
    pathDisplay: json['path_display'] as String,
    pathLower: json['path_lower'] as String,
    isFolder: json['.tag'] == 'folder',
    serverModified: json['server_modified'] == null
        ? null
        : DateTime.parse(json['server_modified'] as String).toLocal(),
    size: (json['size'] as int?) ?? 0,
  );

  final String name;
  final String pathDisplay;
  final String pathLower;
  final bool isFolder;
  final DateTime? serverModified;
  final int size;
}

class DropboxException implements Exception {
  DropboxException(this.statusCode, this.summary);

  final int statusCode;
  final String summary;

  bool get notFound => summary.contains('not_found');

  @override
  String toString() => 'Dropbox ($statusCode): $summary';
}

/// Cliente mínimo de la API HTTP de Dropbox (v2) con lo que usa la app.
class DropboxApi {
  DropboxApi(this._accessToken, {http.Client? client})
    : _client = client ?? http.Client();

  /// Devuelve un token de acceso válido (lo renueva si hace falta).
  final Future<String> Function({bool forceRefresh}) _accessToken;
  final http.Client _client;

  static final _rpc = Uri.https('api.dropboxapi.com', '/2/');
  static final _content = Uri.https('content.dropboxapi.com', '/2/');

  /// Dropbox sólo acepta subidas simples de hasta 150 MB.
  static const maxUploadBytes = 150 * 1024 * 1024;

  /// Lista el contenido directo de [path] ('' es la raíz de Dropbox).
  Future<List<DropboxEntry>> listFolder(String path) async {
    final entries = <DropboxEntry>[];
    var json = await _rpcCall('files/list_folder', {
      'path': path,
      'include_deleted': false,
    });
    while (true) {
      for (final e in json['entries'] as List) {
        final map = e as Map<String, dynamic>;
        if (map['.tag'] == 'file' || map['.tag'] == 'folder') {
          entries.add(DropboxEntry.fromJson(map));
        }
      }
      if (json['has_more'] != true) break;
      json = await _rpcCall('files/list_folder/continue', {
        'cursor': json['cursor'],
      });
    }
    return entries;
  }

  /// Sube [data] a [path]. Si ya existe un archivo con ese nombre, Dropbox
  /// le añade un número en vez de sobrescribirlo.
  Future<DropboxEntry> upload(String path, Uint8List data) async {
    if (data.length > maxUploadBytes) {
      throw DropboxException(413, 'El archivo supera los 150 MB');
    }
    final response = await _send(
      () => http.Request('POST', _content.resolve('files/upload'))
        ..headers['Content-Type'] = 'application/octet-stream'
        ..headers['Dropbox-API-Arg'] = headerSafeJson({
          'path': path,
          'mode': 'add',
          'autorename': true,
          'mute': false,
        })
        ..bodyBytes = data,
    );
    return DropboxEntry.fromJson({
      ...jsonDecode(response.body) as Map<String, dynamic>,
      '.tag': 'file',
    });
  }

  Future<Uint8List> download(String path) async {
    final response = await _send(
      () =>
          http.Request('POST', _content.resolve('files/download'))
            ..headers['Dropbox-API-Arg'] = headerSafeJson({'path': path}),
    );
    return response.bodyBytes;
  }

  /// Enlace temporal (4 horas) para abrir un archivo en el navegador o en
  /// otra app.
  Future<Uri> temporaryLink(String path) async {
    final json = await _rpcCall('files/get_temporary_link', {'path': path});
    return Uri.parse(json['link'] as String);
  }

  Future<Map<String, dynamic>> _rpcCall(
    String endpoint,
    Map<String, dynamic> args,
  ) async {
    final response = await _send(
      () => http.Request('POST', _rpc.resolve(endpoint))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(args),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Envía la petición con el token. Si Dropbox dice que ha caducado, lo
  /// renueva y lo intenta una vez más.
  Future<http.Response> _send(http.Request Function() build) async {
    var response = await _sendOnce(build(), await _accessToken());
    if (response.statusCode == 401) {
      response = await _sendOnce(
        build(),
        await _accessToken(forceRefresh: true),
      );
    }
    if (response.statusCode != 200) {
      throw DropboxException(response.statusCode, _errorSummary(response));
    }
    return response;
  }

  Future<http.Response> _sendOnce(http.Request request, String token) async {
    request.headers['Authorization'] = 'Bearer $token';
    return http.Response.fromStream(await _client.send(request));
  }

  static String _errorSummary(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['error_summary'] as String?) ?? response.body;
    } catch (_) {
      return response.body;
    }
  }
}

/// JSON para la cabecera Dropbox-API-Arg: las cabeceras HTTP sólo admiten
/// ASCII, así que acentos y eñes van escapados como \uXXXX.
@visibleForTesting
String headerSafeJson(Map<String, dynamic> value) {
  final buffer = StringBuffer();
  for (final unit in jsonEncode(value).codeUnits) {
    if (unit < 0x7F) {
      buffer.writeCharCode(unit);
    } else {
      buffer.write('\\u${unit.toRadixString(16).padLeft(4, '0')}');
    }
  }
  return buffer.toString();
}
