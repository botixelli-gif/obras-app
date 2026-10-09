import 'package:flutter/foundation.dart';

import '../models/obra.dart';
import 'stores.dart';

/// Datos de ejemplo en memoria, para probar la app sin conectar nada.
class DemoStore implements ObrasStore, CorreosStore {
  DemoStore({DateTime? ahora}) : _ahora = ahora ?? DateTime.now() {
    _cargarEjemplo();
  }

  final DateTime _ahora;
  final List<Obra> _obras = [];
  final Map<String, List<Documento>> _carpetas = {};
  final Map<String, List<Nota>> _notas = {};
  final List<Correo> _correos = [];
  int _siguienteId = 1;

  @override
  Future<List<Obra>> obras() async => List.of(_obras);

  @override
  Future<List<Documento>> carpeta(String ruta) async =>
      ordenarDocumentos([...?_carpetas[ruta]]);

  @override
  Future<void> subir(String carpeta, String nombre, Uint8List contenido) async {
    _carpetas
        .putIfAbsent(carpeta, () => [])
        .add(
          Documento(
            nombre: nombre,
            ruta: '$carpeta/$nombre',
            modificado: DateTime.now(),
            bytes: contenido.length,
          ),
        );
  }

  @override
  Future<Uri> enlace(Documento documento) async =>
      Uri.https('www.dropbox.com', '/home${documento.ruta}');

  @override
  Future<List<Nota>> notas(Obra obra) async =>
      [...?_notas[obra.id]]..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  Future<void> registrarNota(Obra obra, String texto, String autor) async {
    _notas
        .putIfAbsent(obra.id, () => [])
        .add(
          Nota(
            id: 'c${_siguienteId++}',
            texto: texto,
            autor: autor.isEmpty ? 'Sin nombre' : autor,
            fecha: DateTime.now(),
          ),
        );
  }

  @override
  Future<List<Correo>> correos(Obra obra) async =>
      _correos.where((c) => c.obraId == obra.id).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  Future<List<Correo>> sinAsignar() async =>
      _correos.where((c) => c.obraId == null).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  Future<void> vincular(Correo correo, Obra obra) async {
    final i = _correos.indexWhere((c) => c.id == correo.id);
    if (i >= 0) _correos[i] = _correos[i].asignadoA(obra.id);
  }

  void _cargarEjemplo() {
    DateTime hace(int dias, [int horas = 0]) =>
        _ahora.subtract(Duration(days: dias, hours: horas));

    _obras.addAll(const [
      Obra(
        id: 'mayor12',
        nombre: 'Calle Mayor 12',
        carpetaDropbox: '/Obras/Calle Mayor 12',
      ),
      Obra(
        id: 'nave-sur',
        nombre: 'Nave Polígono Sur',
        carpetaDropbox: '/Obras/Nave Polígono Sur',
      ),
      Obra(
        id: 'colegio',
        nombre: 'Reforma Colegio San José',
        carpetaDropbox: '/Obras/Reforma Colegio San José',
      ),
    ]);

    _carpetas['/Obras/Calle Mayor 12'] = [
      Documento(
        nombre: 'Planos',
        ruta: '/Obras/Calle Mayor 12/Planos',
        modificado: hace(20),
        esCarpeta: true,
      ),
      Documento(
        nombre: 'Presupuesto v3.pdf',
        ruta: '/Obras/Calle Mayor 12/Presupuesto v3.pdf',
        modificado: hace(4),
        bytes: 482133,
      ),
      Documento(
        nombre: 'Licencia de obra.pdf',
        ruta: '/Obras/Calle Mayor 12/Licencia de obra.pdf',
        modificado: hace(35),
        bytes: 1203344,
      ),
    ];
    _carpetas['/Obras/Calle Mayor 12/Planos'] = [
      Documento(
        nombre: 'Planta baja.pdf',
        ruta: '/Obras/Calle Mayor 12/Planos/Planta baja.pdf',
        modificado: hace(20),
        bytes: 2203344,
      ),
    ];
    _carpetas['/Obras/Nave Polígono Sur'] = [
      Documento(
        nombre: 'Estudio geotécnico.pdf',
        ruta: '/Obras/Nave Polígono Sur/Estudio geotécnico.pdf',
        modificado: hace(12),
        bytes: 3402211,
      ),
    ];

    _notas['mayor12'] = [
      Nota(
        id: 'c-ej1',
        texto: 'Se cambia el alicatado del baño 2 a gres porcelánico 60x60.',
        autor: 'Carlos',
        fecha: hace(2),
      ),
      Nota(
        id: 'c-ej2',
        texto: 'Retraso de 3 días en la entrega de ventanas.',
        autor: 'Equipo',
        fecha: hace(6),
      ),
    ];

    _correos.addAll([
      Correo(
        id: 'm1',
        asunto: 'Presupuesto revisado Calle Mayor 12',
        remitente: 'Construcciones López <presupuestos@lopez.es>',
        fecha: hace(4),
        extracto: 'Adjuntamos la versión 3 del presupuesto con los cambios…',
        adjuntos: const ['Presupuesto v3.pdf'],
        obraId: 'mayor12',
      ),
      Correo(
        id: 'm2',
        asunto: 'Pedido de ferralla para la nave',
        remitente: 'Hierros del Sur <pedidos@hierrosdelsur.es>',
        fecha: hace(0, 3),
        extracto: 'Confirmamos el pedido para el lunes. Necesitamos que…',
        adjuntos: const ['Albarán 2231.pdf'],
      ),
      Correo(
        id: 'm3',
        asunto: 'Visita de la dirección facultativa',
        remitente: 'Ana Ruiz <ana.ruiz@arquitectura.es>',
        fecha: hace(1),
        extracto: 'Te propongo pasar por el colegio el jueves a las 10…',
      ),
    ]);
  }
}

/// Carpetas primero, luego archivos, cada grupo por nombre.
List<Documento> ordenarDocumentos(List<Documento> docs) => docs
  ..sort((a, b) {
    if (a.esCarpeta != b.esCarpeta) return a.esCarpeta ? -1 : 1;
    return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
  });
