import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obras_app/dropbox/dropbox_api.dart';
import 'package:obras_app/dropbox/dropbox_auth.dart';
import 'package:obras_app/dropbox/dropbox_store.dart';
import 'package:obras_app/models/obra.dart';

class MemoriaTokens implements TokenStore {
  final valores = <String, String>{};

  @override
  Future<String?> read(String key) async => valores[key];

  @override
  Future<void> write(String key, String value) async => valores[key] = value;

  @override
  Future<void> delete(String key) async => valores.remove(key);
}

Map<String, dynamic> carpeta(String ruta) => {
  '.tag': 'folder',
  'name': ruta.split('/').last,
  'path_display': ruta,
  'path_lower': ruta.toLowerCase(),
};

Map<String, dynamic> archivo(String ruta, {int size = 10}) => {
  '.tag': 'file',
  'name': ruta.split('/').last,
  'path_display': ruta,
  'path_lower': ruta.toLowerCase(),
  'server_modified': '2026-10-01T10:00:00Z',
  'size': size,
};

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('headerSafeJson', () {
    test('escapa acentos y eñes', () {
      final s = headerSafeJson({'path': '/Obras/Año Señorío/Ático.pdf'});
      expect(s, isNot(contains('ñ')));
      expect(s.codeUnits.every((c) => c < 0x7F), isTrue);
      expect(jsonDecode(s), {'path': '/Obras/Año Señorío/Ático.pdf'});
    });
  });

  group('DropboxApi', () {
    test('sigue la paginación de list_folder e ignora borrados', () async {
      final api = DropboxApi(
        ({forceRefresh = false}) async => 't',
        client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer t');
          if (r.url.path == '/2/files/list_folder') {
            expect(jsonDecode(r.body)['path'], '/Obras');
            return json({
              'entries': [
                carpeta('/Obras/A'),
                {'.tag': 'deleted', 'name': 'x', 'path_lower': '/obras/x'},
              ],
              'has_more': true,
              'cursor': 'c1',
            });
          }
          expect(r.url.path, '/2/files/list_folder/continue');
          expect(jsonDecode(r.body)['cursor'], 'c1');
          return json({
            'entries': [carpeta('/Obras/B')],
            'has_more': false,
            'cursor': 'c2',
          });
        }),
      );
      final entries = await api.listFolder('/Obras');
      expect(entries.map((e) => e.name), ['A', 'B']);
    });

    test('si el token ha caducado lo renueva y reintenta', () async {
      final pedidos = <bool>[];
      var llamadas = 0;
      final api = DropboxApi(
        ({forceRefresh = false}) async {
          pedidos.add(forceRefresh);
          return forceRefresh ? 'nuevo' : 'viejo';
        },
        client: MockClient((r) async {
          llamadas++;
          if (r.headers['Authorization'] == 'Bearer viejo') {
            return json({'error_summary': 'expired_access_token/'}, 401);
          }
          return json({'entries': [], 'has_more': false, 'cursor': ''});
        }),
      );
      await api.listFolder('/Obras');
      expect(pedidos, [false, true]);
      expect(llamadas, 2);
    });

    test('los errores llevan el resumen de Dropbox', () async {
      final api = DropboxApi(
        ({forceRefresh = false}) async => 't',
        client: MockClient(
          (r) async => json({'error_summary': 'path/not_found/..'}, 409),
        ),
      );
      expect(
        api.listFolder('/No'),
        throwsA(
          isA<DropboxException>().having((e) => e.notFound, 'notFound', isTrue),
        ),
      );
    });
  });

  group('DropboxStore', () {
    late List<http.Request> peticiones;
    late Map<String, List<Map<String, dynamic>>> carpetas;
    late Map<String, String> contenidos;

    DropboxStore store() => DropboxStore(
      DropboxApi(
        ({forceRefresh = false}) async => 't',
        client: MockClient((r) async {
          peticiones.add(r);
          switch (r.url.path) {
            case '/2/files/list_folder':
              final ruta = jsonDecode(r.body)['path'] as String;
              final entries = carpetas[ruta];
              if (entries == null) {
                return json({'error_summary': 'path/not_found/'}, 409);
              }
              return json({
                'entries': entries,
                'has_more': false,
                'cursor': '',
              });
            case '/2/files/download':
              final arg = jsonDecode(r.headers['Dropbox-API-Arg']!);
              return http.Response.bytes(
                utf8.encode(contenidos[arg['path']]!),
                200,
              );
            case '/2/files/upload':
              final arg = jsonDecode(r.headers['Dropbox-API-Arg']!);
              return json({
                'name': (arg['path'] as String).split('/').last,
                'path_display': arg['path'],
                'path_lower': (arg['path'] as String).toLowerCase(),
                'size': r.bodyBytes.length,
              });
          }
          return json({'error_summary': 'desconocido'}, 400);
        }),
      ),
      'Obras/',
    );

    const obra = Obra(
      id: '/obras/calle mayor 12',
      nombre: 'Calle Mayor 12',
      carpetaDropbox: '/Obras/Calle Mayor 12',
    );

    setUp(() {
      peticiones = [];
      contenidos = {};
      carpetas = {
        '/Obras': [
          carpeta('/Obras/Nave Sur'),
          carpeta('/Obras/Calle Mayor 12'),
          archivo('/Obras/Listado.xlsx'),
        ],
        '/Obras/Calle Mayor 12': [
          archivo('/Obras/Calle Mayor 12/Presupuesto.pdf'),
          carpeta('/Obras/Calle Mayor 12/Notas'),
          carpeta('/Obras/Calle Mayor 12/Planos'),
        ],
        '/Obras/Calle Mayor 12/Planos': [
          carpeta('/Obras/Calle Mayor 12/Planos/Notas'),
        ],
      };
    });

    test('las obras son las subcarpetas de la raíz, por nombre', () async {
      final obras = await store().obras();
      expect(obras.map((o) => o.nombre), ['Calle Mayor 12', 'Nave Sur']);
      expect(obras.first.carpetaDropbox, '/Obras/Calle Mayor 12');
    });

    test('la carpeta Notas sólo se oculta en la raíz de la obra', () async {
      final docs = await store().carpeta(obra.carpetaDropbox);
      expect(docs.map((d) => d.nombre), ['Planos', 'Presupuesto.pdf']);

      final planos = await store().carpeta('/Obras/Calle Mayor 12/Planos');
      expect(planos.map((d) => d.nombre), ['Notas']);
    });

    test('sin carpeta Notas no hay notas', () async {
      expect(await store().notas(obra), isEmpty);
    });

    test('lee las notas, más recientes primero', () async {
      carpetas['/Obras/Calle Mayor 12/Notas'] = [
        archivo('/Obras/Calle Mayor 12/Notas/2026-10-01 09.00.00 - Ana.txt'),
        archivo('/Obras/Calle Mayor 12/Notas/2026-10-05 18.30.00 - Luis.txt'),
        archivo('/Obras/Calle Mayor 12/Notas/foto.jpg'),
      ];
      contenidos['/obras/calle mayor 12/notas/2026-10-01 09.00.00 - ana.txt'] =
          'Replanteo hecho\n';
      contenidos['/obras/calle mayor 12/notas/2026-10-05 18.30.00 - luis.txt'] =
          'Llega la grúa el lunes';

      final notas = await store().notas(obra);
      expect(notas.map((n) => n.autor), ['Luis', 'Ana']);
      expect(notas.first.texto, 'Llega la grúa el lunes');
      expect(notas.last.texto, 'Replanteo hecho');
      expect(notas.first.fecha, DateTime(2026, 10, 5, 18, 30));
    });

    test(
      'una nota nueva es un archivo en Notas firmado por su autor',
      () async {
        await store().registrarNota(obra, 'Cambio de alicatado', 'Lucía');
        final subida = peticiones.single;
        final arg = jsonDecode(subida.headers['Dropbox-API-Arg']!);
        expect(
          arg['path'],
          matches(
            RegExp(
              r'^/Obras/Calle Mayor 12/Notas/'
              r'\d{4}-\d{2}-\d{2} \d{2}\.\d{2}\.\d{2} - Lucía\.txt$',
            ),
          ),
        );
        expect(arg['mode'], 'add');
        expect(utf8.decode(subida.bodyBytes), 'Cambio de alicatado');
      },
    );

    test('subir quita caracteres que Dropbox no admite', () async {
      await store().subir(
        obra.carpetaDropbox,
        'Acta 1/2: "final".pdf',
        utf8.encode('x'),
      );
      final arg = jsonDecode(peticiones.single.headers['Dropbox-API-Arg']!);
      expect(arg['path'], '/Obras/Calle Mayor 12/Acta 1_2_ _final_.pdf');
    });
  });

  group('NombreNota y rutas', () {
    test('crear y leer son simétricos', () {
      final nombre = NombreNota.crear(DateTime(2026, 3, 4, 5, 6, 7), 'Ana B.');
      expect(nombre, '2026-03-04 05.06.07 - Ana B..txt');
      final leida = NombreNota.leer(nombre, null);
      expect(leida.autor, 'Ana B.');
      expect(leida.fecha, DateTime(2026, 3, 4, 5, 6, 7));
    });

    test('una nota creada a mano usa la fecha de Dropbox', () {
      final f = DateTime(2026, 1, 2);
      final leida = NombreNota.leer('Pendientes.txt', f);
      expect(leida.autor, 'Pendientes');
      expect(leida.fecha, f);
    });

    test('normalizarRuta', () {
      expect(normalizarRuta('Obras/'), '/Obras');
      expect(normalizarRuta(' /Obras//2026 '), '/Obras/2026');
      expect(normalizarRuta('/'), '');
      expect(normalizarRuta(''), '');
    });
  });

  group('DropboxAuth', () {
    test('conecta con PKCE y guarda el refresh token', () async {
      final tokens = MemoriaTokens();
      late Uri autorizacion;
      final auth = DropboxAuth(
        appKey: 'clave',
        store: tokens,
        now: () => DateTime(2026, 10, 9, 12),
        authenticate: (url, scheme) async {
          autorizacion = url;
          expect(scheme, 'obrasapp');
          return 'obrasapp://dropbox?code=CODIGO';
        },
        client: MockClient((r) async {
          expect(r.url.toString(), 'https://api.dropboxapi.com/oauth2/token');
          final body = Uri.splitQueryString(r.body);
          expect(body['grant_type'], 'authorization_code');
          expect(body['code'], 'CODIGO');
          expect(body['client_id'], 'clave');
          expect(body['redirect_uri'], 'obrasapp://dropbox');
          expect(body['code_verifier'], isNotEmpty);
          return json({
            'access_token': 'acceso',
            'refresh_token': 'refresco',
            'expires_in': 14400,
          });
        }),
      );

      await auth.conectar();

      final q = autorizacion.queryParameters;
      expect(autorizacion.host, 'www.dropbox.com');
      expect(q['client_id'], 'clave');
      expect(q['code_challenge_method'], 'S256');
      expect(q['token_access_type'], 'offline');
      expect(tokens.valores['dropbox_refresh_token'], 'refresco');
      expect(await auth.conectado, isTrue);
      expect(await auth.accessToken(), 'acceso');
    });

    test('renueva el token cuando caduca', () async {
      final tokens = MemoriaTokens()
        ..valores.addAll({
          'dropbox_refresh_token': 'refresco',
          'dropbox_access_token': 'viejo',
          'dropbox_access_expires': DateTime(2026, 10, 9, 8).toIso8601String(),
        });
      final auth = DropboxAuth(
        appKey: 'clave',
        store: tokens,
        now: () => DateTime(2026, 10, 9, 12),
        client: MockClient((r) async {
          final body = Uri.splitQueryString(r.body);
          expect(body['grant_type'], 'refresh_token');
          expect(body['refresh_token'], 'refresco');
          return json({'access_token': 'nuevo', 'expires_in': 14400});
        }),
      );
      expect(await auth.accessToken(), 'nuevo');
      expect(tokens.valores['dropbox_access_token'], 'nuevo');
    });

    test('si el usuario cancela en Dropbox no queda conectado', () async {
      final tokens = MemoriaTokens();
      final auth = DropboxAuth(
        appKey: 'clave',
        store: tokens,
        authenticate: (url, scheme) async =>
            'obrasapp://dropbox?error=access_denied',
        client: MockClient((r) async => fail('no debe pedir token')),
      );
      await expectLater(auth.conectar(), throwsStateError);
      expect(await auth.conectado, isFalse);
    });
  });
}
