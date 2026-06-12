/// Balance neto de un miembro dentro de un grupo (calculado en cliente,
/// no se persiste). `netAmount` > 0 significa que le deben dinero;
/// `netAmount` < 0 significa que debe dinero.
class MemberBalance {
  final String memberId;
  final double paid;
  final double owed;

  MemberBalance({
    required this.memberId,
    required this.paid,
    required this.owed,
  });

  double get netAmount => paid - owed;
}

/// Deuda simplificada entre dos miembros: `fromMemberId` debe `amount` a
/// `toMemberId`.
class DebtTransfer {
  final String fromMemberId;
  final String toMemberId;
  final double amount;

  DebtTransfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });
}
