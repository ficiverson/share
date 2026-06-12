import 'split.dart';

/// Gasto registrado en un grupo. Documento de la subcolección
/// `groups/{groupId}/expenses/{expenseId}`, con los repartos (`splits`)
/// embebidos como array.
class Expense {
  final String expenseId;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final String paidBy; // memberId (uid)
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

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
        'currency': currency,
        'category': category,
        'paidBy': paidBy,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'splits': splits.map((s) => s.toMap()).toList(),
      };

  factory Expense.fromMap(String expenseId, Map<String, dynamic> map) => Expense(
        expenseId: expenseId,
        description: map['description'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] as String? ?? 'EUR',
        category: map['category'] as String? ?? '',
        paidBy: map['paidBy'] as String? ?? '',
        date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        notes: map['notes'] as String? ?? '',
        splits: ((map['splits'] as List?) ?? const [])
            .map((s) => Split.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList(),
      );
}
