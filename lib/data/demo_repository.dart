import 'package:flutter/foundation.dart';

import '../models/obra.dart';
import 'obras_repository.dart';

/// Datos de ejemplo en memoria, para probar la app antes de conectar
/// Dropbox, Firebase y Gmail.
class DemoRepository extends ObrasRepository {
  DemoRepository({DateTime? ahora}) : _ahora = ahora ?? DateTime.now() {
    _cargarEjemplo();
  }

  final DateTime _ahora;
  final List<Obra> _obras = [];
  final Map<String, List<Documento>> _documentos = {};
  final List<Cambio> _cambios = [];
  final List<Correo> _correos = [];
  int _siguienteId = 1;

  @override
  String get origen => 'Modo demostración: datos de ejemplo';

  @override
  List<Obra> get obras => List.unmodifiable(_obras);

  @override
  Obra? obra(String id) {
    for (final o in _obras) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Future<List<Documento>> documentos(String obraId) async {
    final lista = [...?_documentos[obraId]];
    lista.sort((a, b) {
      if (a.esCarpeta != b.esCarpeta) return a.esCarpeta ? -1 : 1;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return lista;
  }

  @override
  Future<void> subirDocumento(
    String obraId,
    String nombre,
    Uint8List contenido,
  ) async {
    final obra = this.obra(obraId)!;
    _documentos.putIfAbsent(obraId, () => []).add(Documento(
          nombre: nombre,
          ruta: '${obra.carpetaDropbox}/$nombre',
          modificado: DateTime.now(),
          bytes: contenido.length,
        ));
    notifyListeners();
  }

  @override
  List<Cambio> cambios(String obraId) =>
      _cambios.where((c) => c.obraId == obraId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  Future<void> registrarCambio(String obraId, String texto) async {
    _cambios.add(Cambio(
      id: 'c${_siguienteId++}',
      obraId: obraId,
      texto: texto,
      autor: 'Yo',
      fecha: DateTime.now(),
    ));
    notifyListeners();
  }

  @override
  List<Correo> correos(String obraId) =>
      _correos.where((c) => c.obraId == obraId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  List<Correo> get sinAsignar =>
      _correos.where((c) => c.obraId == null).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  Future<void> vincularCorreo(String correoId, String obraId) async {
    final i = _correos.indexWhere((c) => c.id == correoId);
    if (i < 0) return;
    _correos[i] = _correos[i].asignadoA(obraId);
    notifyListeners();
  }

  void _cargarEjemplo() {
    DateTime hace(int dias, [int horas = 0]) =>
        _ahora.subtract(Duration(days: dias, hours: horas));

    _obras.addAll(const [
      Obra(
        id: 'mayor12',
        nombre: 'Calle Mayor 12',
        carpetaDropbox: '/Obras/Calle Mayor 12',
        direccion: 'C/ Mayor 12, bajo',
      ),
      Obra(
        id: 'nave-sur',
        nombre: 'Nave Polígono Sur',
        carpetaDropbox: '/Obras/Nave Polígono Sur',
        direccion: 'Parcela 34, Polígono Sur',
      ),
      Obra(
        id: 'colegio',
        nombre: 'Reforma Colegio San José',
        carpetaDropbox: '/Obras/Reforma Colegio San José',
      ),
    ]);

    _documentos['mayor12'] = [
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
    _documentos['nave-sur'] = [
      Documento(
        nombre: 'Estudio geotécnico.pdf',
        ruta: '/Obras/Nave Polígono Sur/Estudio geotécnico.pdf',
        modificado: hace(12),
        bytes: 3402211,
      ),
    ];

    _cambios.addAll([
      Cambio(
        id: 'c-ej1',
        obraId: 'mayor12',
        texto: 'Se cambia el alicatado del baño 2 a gres porcelánico 60x60.',
        autor: 'Carlos',
        fecha: hace(2),
      ),
      Cambio(
        id: 'c-ej2',
        obraId: 'mayor12',
        texto: 'Retraso de 3 días en la entrega de ventanas.',
        autor: 'Equipo',
        fecha: hace(6),
      ),
    ]);

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
