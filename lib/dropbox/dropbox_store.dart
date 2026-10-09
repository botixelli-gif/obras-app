import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/demo_store.dart' show ordenarDocumentos;
import '../data/stores.dart';
import '../models/obra.dart';
import '../widgets/formato.dart';
import 'dropbox_api.dart';

/// Obras = subcarpetas de [raiz] en Dropbox. Las notas de cada obra son
/// archivos de texto en su subcarpeta `Notas`, un archivo por nota, para que
/// dos personas escribiendo a la vez no se pisen.
class DropboxStore implements ObrasStore {
  DropboxStore(this._api, String raiz) : raiz = normalizarRuta(raiz);

  final DropboxApi _api;
  final String raiz;

  static const carpetaNotas = 'Notas';

  /// Cuántas notas se descargan por obra (las más recientes).
  static const maxNotas = 100;

  @override
  Future<List<Obra>> obras() async {
    final entries = await _api.listFolder(raiz);
    final obras = [
      for (final e in entries)
        if (e.isFolder)
          Obra(id: e.pathLower, nombre: e.name, carpetaDropbox: e.pathDisplay),
    ];
    obras.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    return obras;
  }

  @override
  Future<List<Documento>> carpeta(String ruta) async {
    final entries = await _api.listFolder(ruta);
    final esRaizDeObra = _padre(ruta).toLowerCase() == raiz.toLowerCase();
    return ordenarDocumentos([
      for (final e in entries)
        // Las notas tienen su propia pestaña.
        if (!(esRaizDeObra &&
            e.isFolder &&
            e.name.toLowerCase() == carpetaNotas.toLowerCase()))
          Documento(
            nombre: e.name,
            ruta: e.pathDisplay,
            modificado: e.serverModified ?? DateTime.now(),
            bytes: e.size,
            esCarpeta: e.isFolder,
          ),
    ]);
  }

  @override
  Future<void> subir(String carpeta, String nombre, Uint8List contenido) =>
      _api.upload('$carpeta/${nombreSeguro(nombre)}', contenido);

  @override
  Future<Uri> enlace(Documento documento) => _api.temporaryLink(documento.ruta);

  @override
  Future<List<Nota>> notas(Obra obra) async {
    final List<DropboxEntry> entries;
    try {
      entries = await _api.listFolder('${obra.carpetaDropbox}/$carpetaNotas');
    } on DropboxException catch (e) {
      if (e.notFound) return const [];
      rethrow;
    }
    final notas = [
      for (final e in entries)
        if (!e.isFolder && e.name.toLowerCase().endsWith('.txt'))
          (entry: e, info: NombreNota.leer(e.name, e.serverModified)),
    ]..sort((a, b) => b.info.fecha.compareTo(a.info.fecha));

    return Future.wait([
      for (final n in notas.take(maxNotas))
        _api
            .download(n.entry.pathLower)
            .then(
              (bytes) => Nota(
                id: n.entry.pathLower,
                texto: utf8.decode(bytes, allowMalformed: true).trim(),
                autor: n.info.autor,
                fecha: n.info.fecha,
              ),
            ),
    ]);
  }

  @override
  Future<void> registrarNota(Obra obra, String texto, String autor) {
    final nombre = NombreNota.crear(DateTime.now(), autor);
    return _api.upload(
      '${obra.carpetaDropbox}/$carpetaNotas/$nombre',
      utf8.encode(texto),
    );
  }

  static String _padre(String ruta) {
    final i = ruta.lastIndexOf('/');
    return i <= 0 ? '' : ruta.substring(0, i);
  }
}

/// Nombre de archivo de una nota: `2026-10-09 21.10.05 - Carlos.txt`.
/// Así se ordenan por fecha también en Dropbox y se ve quién la escribió.
class NombreNota {
  const NombreNota(this.fecha, this.autor);

  final DateTime fecha;
  final String autor;

  static final _patron = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2}) (\d{2})\.(\d{2})(?:\.(\d{2}))? - (.+)\.txt$',
    caseSensitive: false,
  );

  static String crear(DateTime f, String autor) {
    final nombre = nombreSeguro(autor.trim().isEmpty ? 'Sin nombre' : autor);
    return '${f.year}-${dosDigitos(f.month)}-${dosDigitos(f.day)} '
        '${dosDigitos(f.hour)}.${dosDigitos(f.minute)}.${dosDigitos(f.second)}'
        ' - $nombre.txt';
  }

  /// Si el archivo no sigue el formato (lo creó alguien a mano), usa la fecha
  /// de Dropbox y el nombre del archivo como autor.
  static NombreNota leer(String archivo, DateTime? modificado) {
    final m = _patron.firstMatch(archivo);
    if (m == null) {
      return NombreNota(
        modificado ?? DateTime.fromMillisecondsSinceEpoch(0),
        archivo.replaceFirst(RegExp(r'\.txt$', caseSensitive: false), ''),
      );
    }
    int n(int i) => int.parse(m.group(i) ?? '0');
    return NombreNota(
      DateTime(n(1), n(2), n(3), n(4), n(5), n(6)),
      m.group(7)!,
    );
  }
}

/// `Obras/` -> `/Obras`; `/` o vacío -> raíz de Dropbox ('').
String normalizarRuta(String ruta) {
  var r = ruta.trim().replaceAll(RegExp(r'/+'), '/');
  if (r.endsWith('/')) r = r.substring(0, r.length - 1);
  if (r.isEmpty) return '';
  return r.startsWith('/') ? r : '/$r';
}

/// Quita caracteres que Dropbox no admite en nombres de archivo.
String nombreSeguro(String nombre) =>
    nombre.replaceAll(RegExp(r'[/\\<>:"|?*\x00-\x1F]'), '_').trim();
