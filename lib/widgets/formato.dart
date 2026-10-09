String dosDigitos(int n) => n.toString().padLeft(2, '0');

String formatoFecha(DateTime f) =>
    '${dosDigitos(f.day)}/${dosDigitos(f.month)}/${f.year}';

String formatoFechaHora(DateTime f) =>
    '${formatoFecha(f)} ${dosDigitos(f.hour)}:${dosDigitos(f.minute)}';

String formatoTamano(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
