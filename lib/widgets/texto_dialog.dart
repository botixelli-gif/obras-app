import 'package:flutter/material.dart';

/// Diálogo con un campo de texto. Devuelve el texto o null si se cancela.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  String inicial = '',
  String? pista,
  String? ayuda,
  int lineas = 1,
  TextCapitalization mayusculas = TextCapitalization.none,
}) => showDialog<String>(
  context: context,
  builder: (context) => _TextoDialog(
    titulo: titulo,
    inicial: inicial,
    pista: pista,
    ayuda: ayuda,
    lineas: lineas,
    mayusculas: mayusculas,
  ),
);

class _TextoDialog extends StatefulWidget {
  const _TextoDialog({
    required this.titulo,
    required this.inicial,
    required this.pista,
    required this.ayuda,
    required this.lineas,
    required this.mayusculas,
  });

  final String titulo;
  final String inicial;
  final String? pista;
  final String? ayuda;
  final int lineas;
  final TextCapitalization mayusculas;

  @override
  State<_TextoDialog> createState() => _TextoDialogState();
}

class _TextoDialogState extends State<_TextoDialog> {
  late final _texto = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multilinea = widget.lineas > 1;
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _texto,
        autofocus: true,
        minLines: widget.lineas,
        maxLines: multilinea ? widget.lineas * 2 : 1,
        textCapitalization: widget.mayusculas,
        decoration: InputDecoration(
          hintText: widget.pista,
          helperText: widget.ayuda,
          border: multilinea ? const OutlineInputBorder() : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _texto.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
