import 'package:share_app/models/balance.dart';
import 'package:share_app/models/settlement.dart';

/// Contrato del repositorio de balances/liquidaciones. Implementado en
/// `data/balances_repository.dart` (Fase 4).
abstract class BalancesRepositoryContract {
  /// Balance neto por miembro, ya calculado a partir de Expenses + Splits +
  /// Settlements (ver `calculate_balances_use_case.dart`).
  Future<List<MemberBalance>> getBalances(String groupSpreadsheetId);

  /// Registra una liquidación entre dos miembros (fila en "Settlements").
  Future<Settlement> settleUp(String groupSpreadsheetId, Settlement settlement);
}
