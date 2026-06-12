import 'split.dart';

/// Gasto registrado en un grupo. Fila de la hoja "Expenses" + sus filas
/// relacionadas en "Splits".
class Expense {
  final String expenseId;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final String paidBy; // memberId
  final DateTime date;
  final DateTime createdAt;
  final String notes;
  final List<Split> splits;

  Expense({
    required this.expenseId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.paidBy,
    required this.date,
    required this.createdAt,
    this.notes = '',
    this.splits = const [],
  });

  /// Fila de "Expenses": expense_id | description | amount | currency |
  /// category | paid_by | date | created_at | notes
  List<dynamic> toRow() => [
        expenseId,
        description,
        amount,
        currency,
        category,
        paidBy,
        date.toIso8601String(),
        createdAt.toIso8601String(),
        notes,
      ];

  factory Expense.fromRow(List<dynamic> row, {List<Split> splits = const []}) =>
      Expense(
        expenseId: row.isNotEmpty ? row[0].toString() : '',
        description: row.length > 1 ? row[1].toString() : '',
        amount: row.length > 2 ? double.tryParse(row[2].toString()) ?? 0 : 0,
        currency: row.length > 3 ? row[3].toString() : 'EUR',
        category: row.length > 4 ? row[4].toString() : '',
        paidBy: row.length > 5 ? row[5].toString() : '',
        date: row.length > 6 && row[6].toString().isNotEmpty
            ? DateTime.parse(row[6].toString())
            : DateTime.now(),
        createdAt: row.length > 7 && row[7].toString().isNotEmpty
            ? DateTime.parse(row[7].toString())
            : DateTime.now(),
        notes: row.length > 8 ? row[8].toString() : '',
        splits: splits,
      );
}
