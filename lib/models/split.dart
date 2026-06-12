/// Cómo se divide un gasto entre un miembro. Fila de la hoja "Splits".
enum ShareType { equal, exact, percentage }

class Split {
  final String splitId;
  final String expenseId;
  final String memberId;
  final double shareAmount;
  final ShareType shareType;

  Split({
    required this.splitId,
    required this.expenseId,
    required this.memberId,
    required this.shareAmount,
    this.shareType = ShareType.equal,
  });

  factory Split.fromRow(List<dynamic> row) => Split(
        splitId: row.isNotEmpty ? row[0].toString() : '',
        expenseId: row.length > 1 ? row[1].toString() : '',
        memberId: row.length > 2 ? row[2].toString() : '',
        shareAmount: row.length > 3 ? double.tryParse(row[3].toString()) ?? 0 : 0,
        shareType: row.length > 4
            ? ShareType.values.firstWhere(
                (e) => e.name == row[4].toString(),
                orElse: () => ShareType.equal,
              )
            : ShareType.equal,
      );

  List<dynamic> toRow() => [
        splitId,
        expenseId,
        memberId,
        shareAmount,
        shareType.name,
      ];
}
