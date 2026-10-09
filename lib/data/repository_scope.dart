import 'package:flutter/widgets.dart';

import 'obras_repository.dart';

/// Hace accesible el [ObrasRepository] a todas las pantallas y las redibuja
/// cuando cambian los datos.
class RepositoryScope extends InheritedNotifier<ObrasRepository> {
  const RepositoryScope({
    super.key,
    required ObrasRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static ObrasRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'No hay RepositoryScope en el árbol');
    return scope!.notifier!;
  }

  /// Igual que [of] pero sin redibujar al cambiar los datos (para acciones).
  static ObrasRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'No hay RepositoryScope en el árbol');
    return scope!.notifier!;
  }
}
