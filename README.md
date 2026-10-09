# Obras

App para Android e iPhone que reúne por obra los documentos de Dropbox, los
correos de Gmail y las notas del equipo.

El plan completo está en el proyecto ("Plan de la app de obras").

## Estado
- Esqueleto de la app con datos de ejemplo (`DemoRepository`).
- Próximo paso: conexión con Dropbox.

## Estructura
- `lib/models/`: obra, documento, nota/cambio, correo.
- `lib/data/obras_repository.dart`: interfaz única de datos. Las pantallas no
  saben si los datos vienen de ejemplo, de Dropbox o de Gmail.
- `lib/screens/`: Obras, ficha de obra, Sin asignar, Ajustes.

## Desarrollo
```
flutter pub get
flutter analyze
flutter test
flutter run
```

## Compilación
Cada cambio en `main` compila el APK de Android en GitHub Actions
(pestaña *Actions* → última ejecución → *obras-android*).

Para que las actualizaciones se instalen encima de la versión anterior, el APK
debe firmarse siempre con la misma clave. Se configura con dos secretos del
repositorio: `ANDROID_KEYSTORE_BASE64` y `ANDROID_KEYSTORE_PASSWORD`. Sin
ellos se firma con una clave de depuración distinta en cada compilación.
