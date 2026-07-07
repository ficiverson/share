import 'split.dart';

/// Gasto registrado en un grupo. Documento de la subcolección
/// `groups/{groupId}/expenses/{expenseId}`, con los repartos (`splits`)
/// y los pagos (`payments`) embebidos como arrays.
///
/// `payments` vacío → un solo pagador indicado en `paidBy`.
/// `payments` no vacío → varios pagadores; `paidBy` es el de mayor importe.
class Expense {
  final String expenseId;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final String paidBy;    // memberId del pagador principal (o único)
  final String createdBy; // uid del usuario que registró el gasto
  final DateTime date;
  final DateTime createdAt;
  final String notes;
  final List<Split> splits;
  /// Pagos individuales cuando el gasto lo pagan varios miembros.
  /// Vacío = pago único por [paidBy].
  final List<Split> payments;

  Expense({
    required this.expenseId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.paidBy,
    this.createdBy = '',
    required this.date,
    required this.createdAt,
    this.notes = '',
    this.splits = const [],
    this.payments = const [],
  });

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
        'currency': currency,
        'category': category,
        'paidBy': paidBy,
        'createdBy': createdBy,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'splits': splits.map((s) => s.toMap()).toList(),
        'payments': payments.map((p) => p.toMap()).toList(),
      };

  factory Expense.fromMap(String expenseId, Map<String, dynamic> map) => Expense(
        expenseId: expenseId,
        description: map['description'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] as String? ?? 'EUR',
        category: map['category'] as String? ?? '',
        paidBy: map['paidBy'] as String? ?? '',
        createdBy: map['createdBy'] as String? ?? '',
        date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        notes: map['notes'] as String? ?? '',
        splits: ((map['splits'] as List?) ?? const [])
            .map((s) => Split.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList(),
        payments: ((map['payments'] as List?) ?? const [])
            .map((p) => Split.fromMap(Map<String, dynamic>.from(p as Map)))
            .toList(),
      );
}
