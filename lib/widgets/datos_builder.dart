import 'package:flutter/material.dart';

import '../data/obras_repository.dart';
import '../data/repository_scope.dart';

/// Carga datos del repositorio y los vuelve a cargar cuando cambian (por
/// ejemplo, al subir un archivo) o al tirar de la lista hacia abajo.
class DatosBuilder<T> extends StatefulWidget {
  const DatosBuilder({super.key, required this.cargar, required this.builder});

  final Future<T> Function(ObrasRepository repo) cargar;

  /// Debe devolver algo desplazable (una lista) para poder recargar.
  final Widget Function(BuildContext context, T datos) builder;

  @override
  State<DatosBuilder<T>> createState() => _DatosBuilderState<T>();
}

class _DatosBuilderState<T> extends State<DatosBuilder<T>> {
  late Future<T> _datos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _datos = widget.cargar(RepositoryScope.of(context));
  }

  Future<void> _recargar() async {
    final datos = widget.cargar(RepositoryScope.read(context));
    setState(() => _datos = datos);
    try {
      await datos;
    } catch (_) {
      // El error se muestra en la propia pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _datos,
      builder: (context, snapshot) {
        final Widget contenido;
        if (snapshot.hasError) {
          contenido = ListView(
            children: [
              MensajeVacio(
                icono: Icons.cloud_off,
                texto: 'No se pudo cargar.\n${snapshot.error}',
                accion: TextButton(
                  onPressed: _recargar,
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          );
        } else if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        } else {
          contenido = widget.builder(context, snapshot.data as T);
        }
        return RefreshIndicator(onRefresh: _recargar, child: contenido);
      },
    );
  }
}

/// Icono y texto centrados para listas vacías o errores.
class MensajeVacio extends StatelessWidget {
  const MensajeVacio({
    super.key,
    required this.icono,
    required this.texto,
    this.accion,
  });

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
          ?accion,
        ],
      ),
    );
  }
}

/// Lista vacía que se puede recargar tirando hacia abajo.
Widget listaVacia(IconData icono, String texto) => ListView(
  children: [MensajeVacio(icono: icono, texto: texto)],
);
