/// Liquidación de deuda entre dos miembros. Fila de la hoja "Settlements".
class Settlement {
  final String settlementId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final DateTime date;
  final String notes;

  Settlement({
    required this.settlementId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  factory Settlement.fromRow(List<dynamic> row) => Settlement(
        settlementId: row.isNotEmpty ? row[0].toString() : '',
        fromMemberId: row.length > 1 ? row[1].toString() : '',
        toMemberId: row.length > 2 ? row[2].toString() : '',
        amount: row.length > 3 ? double.tryParse(row[3].toString()) ?? 0 : 0,
        date: row.length > 4 && row[4].toString().isNotEmpty
            ? DateTime.parse(row[4].toString())
            : DateTime.now(),
        notes: row.length > 5 ? row[5].toString() : '',
      );

  List<dynamic> toRow() => [
        settlementId,
        fromMemberId,
        toMemberId,
        amount,
        date.toIso8601String(),
        notes,
      ];
}
