import 'package:flutter/material.dart';

import '../models/obra.dart';
import 'formato.dart';

class CorreoTile extends StatelessWidget {
  const CorreoTile({super.key, required this.correo, this.trailing});

  final Correo correo;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(correo.asunto, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_nombre(correo.remitente)} · ${formatoFecha(correo.fecha)}\n'
        '${correo.extracto}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      leading: correo.adjuntos.isEmpty
          ? const Icon(Icons.mail_outline)
          : const Icon(Icons.attach_email_outlined),
      trailing: trailing,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _DetalleCorreo(correo: correo),
      ),
    );
  }

  /// `Ana Ruiz <ana@x.es>` -> `Ana Ruiz`.
  static String _nombre(String remitente) {
    final i = remitente.indexOf('<');
    return i > 0 ? remitente.substring(0, i).trim() : remitente;
  }
}

class _DetalleCorreo extends StatelessWidget {
  const _DetalleCorreo({required this.correo});

  final Correo correo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(correo.asunto, style: texto.titleLarge),
            const SizedBox(height: 8),
            Text(correo.remitente, style: texto.bodySmall),
            Text(formatoFechaHora(correo.fecha), style: texto.bodySmall),
            const Divider(height: 24),
            Text(correo.extracto),
            if (correo.adjuntos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in correo.adjuntos)
                    Chip(
                      avatar: const Icon(Icons.attachment, size: 18),
                      label: Text(a),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
