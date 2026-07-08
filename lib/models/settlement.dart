/// Liquidación de deuda entre dos miembros. Documento de la subcolección
/// `groups/{groupId}/settlements/{settlementId}`.
class Settlement {
  final String settlementId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String currency;
  final DateTime date;
  final String notes;

  Settlement({
    required this.settlementId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    this.currency = 'EUR',
    required this.date,
    this.notes = '',
  });

  factory Settlement.fromMap(String settlementId, Map<String, dynamic> map) => Settlement(
        settlementId: settlementId,
        fromMemberId: map['fromMemberId'] as String? ?? '',
        toMemberId: map['toMemberId'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] as String? ?? 'EUR',
        date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
        notes: map['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'fromMemberId': fromMemberId,
        'toMemberId': toMemberId,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'notes': notes,
      };
}
