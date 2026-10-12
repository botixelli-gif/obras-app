# Obras

App para Android e iPhone que reúne por obra los documentos de Dropbox, los
correos de Gmail y las notas del equipo.

El plan completo está en el proyecto ("Plan de la app de obras").

## Estado
- Obras, documentos y notas desde Dropbox (cuenta compartida del equipo).
  Sin conectar, la app muestra datos de ejemplo.
- Correos: datos de ejemplo; Gmail es el siguiente paso.

## Dónde se guarda cada cosa
- Obras: cada subcarpeta de la carpeta de obras (por defecto `/Obras`).
- Documentos y fotos subidas: la carpeta de la obra.
- Notas: `<obra>/Notas/AAAA-MM-DD HH.MM.SS - Autor.txt`, un archivo por nota.

## Estructura
- `lib/models/`: obra, documento, nota, correo.
- `lib/data/`: `ObrasRepository` (lo único que ven las pantallas) y los
  orígenes de datos (`ObrasStore`, `CorreosStore`, datos de ejemplo).
- `lib/dropbox/`: API de Dropbox, inicio de sesión (OAuth PKCE) y `DropboxStore`.
- `lib/estado.dart`: ajustes del móvil y qué origen de datos se usa.
- `lib/screens/`: Obras, ficha de obra, carpetas, Sin asignar, Ajustes.

## Desarrollo
```
flutter pub get
flutter analyze
flutter test
flutter run
```

La app de Dropbox (dropbox.com/developers) debe tener permisos
`files.metadata.read`, `files.content.read`, `files.content.write` y la
Redirect URI `obrasapp://dropbox`.

## Compilación
Cada cambio en `main` compila el APK de Android en GitHub Actions y lo publica
como versión. La última siempre está en:
https://github.com/botixelli-gif/obras-app/releases/latest/download/obras.apk

Para que las actualizaciones se instalen encima de la versión anterior, el APK
debe firmarse siempre con la misma clave. Se configura con dos secretos del
repositorio: `ANDROID_KEYSTORE_BASE64` y `ANDROID_KEYSTORE_PASSWORD`. Sin
ellos se firma con una clave de depuración distinta en cada compilación.
