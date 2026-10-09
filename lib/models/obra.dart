/// Una obra en marcha. Su carpeta en Dropbox es la fuente de los documentos.
class Obra {
  const Obra({
    required this.id,
    required this.nombre,
    required this.carpetaDropbox,
    this.direccion,
  });

  final String id;
  final String nombre;
  final String carpetaDropbox;
  final String? direccion;
}

/// Un archivo o subcarpeta dentro de la carpeta de una obra.
class Documento {
  const Documento({
    required this.nombre,
    required this.ruta,
    required this.modificado,
    this.bytes = 0,
    this.esCarpeta = false,
  });

  final String nombre;
  final String ruta;
  final DateTime modificado;
  final int bytes;
  final bool esCarpeta;
}

/// Una nota o cambio de la obra, visible para todo el equipo.
class Nota {
  const Nota({
    required this.id,
    required this.texto,
    required this.autor,
    required this.fecha,
  });

  final String id;
  final String texto;
  final String autor;
  final DateTime fecha;
}

/// Un correo de Gmail. Si [obraId] es null, está pendiente de asignar.
class Correo {
  const Correo({
    required this.id,
    required this.asunto,
    required this.remitente,
    required this.fecha,
    required this.extracto,
    this.adjuntos = const [],
    this.obraId,
  });

  final String id;
  final String asunto;
  final String remitente;
  final DateTime fecha;
  final String extracto;
  final List<String> adjuntos;
  final String? obraId;

  Correo asignadoA(String obraId) => Correo(
    id: id,
    asunto: asunto,
    remitente: remitente,
    fecha: fecha,
    extracto: extracto,
    adjuntos: adjuntos,
    obraId: obraId,
  );
}
