import 'package:share_app/models/balance.dart';
import 'package:share_app/models/settlement.dart';

/// Contrato del repositorio de balances/liquidaciones. Implementado en
/// `data/balances_repository.dart` (Fase 4) sobre la subcolección
/// `groups/{groupId}/settlements` de Firestore (los balances en sí se
/// calculan en cliente a partir de expenses + settlements).
abstract class BalancesRepositoryContract {
  /// Balance neto por miembro, ya calculado a partir de Expenses + Splits +
  /// Settlements (ver `calculate_balances_use_case.dart`).
  Future<List<MemberBalance>> getBalances(String groupId);

  /// Balance neto de un único miembro [uid] en el grupo [groupId].
  /// Más eficiente que `getBalances` cuando solo se necesita el balance propio.
  Future<MemberBalance> getUserBalance(String groupId, String uid);

  Stream<List<Settlement>> watchSettlements(String groupId);

  /// Registra una liquidación entre dos miembros (documento en `settlements`).
  Future<Settlement> settleUp(String groupId, Settlement settlement);
}
