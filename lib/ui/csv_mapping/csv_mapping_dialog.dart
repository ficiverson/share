import 'package:flutter/material.dart';
import 'package:share_app/models/member.dart';

/// Muestra un diálogo para asignar cada columna del CSV de Splitwise a un
/// miembro del grupo. Por defecto muestra el nombre de la columna CSV tal
/// cual aparece en el CSV (para que el usuario pueda mantenerlo o cambiarlo).
///
/// Retorna `Map<String, String>` (csvColumnName → memberId) al confirmar,
/// o `null` si el usuario cancela.
class CsvMappingDialog extends StatefulWidget {
  final List<String> csvColumns;
  final List<Member> members;

  const CsvMappingDialog({
    super.key,
    required this.csvColumns,
    required this.members,
  });

  /// Abre el diálogo y devuelve el mapeo elegido, o null si se cancela.
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required List<String> csvColumns,
    required List<Member> members,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => CsvMappingDialog(csvColumns: csvColumns, members: members),
    );
  }

  @override
  State<CsvMappingDialog> createState() => _CsvMappingDialogState();
}

class _CsvMappingDialogState extends State<CsvMappingDialog> {
  /// Mapeo actual csvColumnName → memberId (o null si "Sin asignar").
  late final Map<String, String?> _mapping;

  @override
  void initState() {
    super.initState();
    _mapping = {
      for (final col in widget.csvColumns) col: _bestMatch(col),
    };
  }

  /// Intenta encontrar el miembro cuyo nombre normalizado coincide mejor con
  /// el nombre de la columna CSV. Devuelve null si no hay coincidencia.
  String? _bestMatch(String csvColumn) {
    final normalized = _normalize(csvColumn);
    for (final member in widget.members) {
      if (_normalize(member.name) == normalized) return member.memberId;
    }
    return null;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar columnas a miembros'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cada columna del CSV de Splitwise aparece aquí con su nombre original. '
              'Asigna cada una al miembro del grupo que le corresponde.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ...widget.csvColumns.map((col) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          col,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String?>(
                          value: _mapping[col],
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Sin asignar', style: TextStyle(color: Colors.black45)),
                            ),
                            ...widget.members.map(
                              (m) => DropdownMenuItem<String?>(
                                value: m.memberId,
                                child: Text(m.name, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _mapping[col] = value),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Solo incluir las columnas que tienen un miembro asignado.
            final result = <String, String>{
              for (final entry in _mapping.entries)
                if (entry.value != null) entry.key: entry.value!,
            };
            Navigator.pop(context, result);
          },
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
