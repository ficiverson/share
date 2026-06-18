import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/balance.dart';

/// Calcula el balance neto por miembro y simplifica las deudas en el menor
/// número de transferencias posible (algoritmo voraz: el mayor deudor paga
/// al mayor acreedor, hasta saldar a ambos o a uno de los dos).
class CalculateBalancesUseCase extends BaseUseCase<String, List<DebtTransfer>> {
  final BalancesRepositoryContract repository;

  CalculateBalancesUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<List<DebtTransfer>>> _run() async {
    try {
      final groupId = params!;
      final balances = await repository.getBalances(groupId);
      return Success(simplifyDebts(balances), Status.ok);
    } catch (e) {
      return Error(<DebtTransfer>[], Status.fail, e.toString());
    }
  }

  /// Algoritmo puro: dado el balance neto de cada miembro, devuelve la lista
  /// mínima de transferencias `DebtTransfer` que liquidan todas las deudas.
  static List<DebtTransfer> simplifyDebts(List<MemberBalance> balances) {
    // Copia mutable: cantidad que cada miembro debe (positivo) o le deben
    // (negativo), con tolerancia para errores de redondeo.
    const epsilon = 0.01;

    final debtors = <String, double>{}; // deben dinero (net < 0)
    final creditors = <String, double>{}; // les deben dinero (net > 0)

    for (final balance in balances) {
      final net = balance.netAmount;
      if (net < -epsilon) {
        debtors[balance.memberId] = -net;
      } else if (net > epsilon) {
        creditors[balance.memberId] = net;
      }
    }

    final transfers = <DebtTransfer>[];

    final debtorIds = debtors.keys.toList()..sort((a, b) => debtors[b]!.compareTo(debtors[a]!));
    final creditorIds = creditors.keys.toList()..sort((a, b) => creditors[b]!.compareTo(creditors[a]!));

    var i = 0;
    var j = 0;
    while (i < debtorIds.length && j < creditorIds.length) {
      final debtorId = debtorIds[i];
      final creditorId = creditorIds[j];
      final debtAmount = debtors[debtorId]!;
      final creditAmount = creditors[creditorId]!;

      final transferAmount = debtAmount < creditAmount ? debtAmount : creditAmount;
      if (transferAmount > epsilon) {
        transfers.add(DebtTransfer(
          fromMemberId: debtorId,
          toMemberId: creditorId,
          amount: double.parse(transferAmount.toStringAsFixed(2)),
        ));
      }

      debtors[debtorId] = debtAmount - transferAmount;
      creditors[creditorId] = creditAmount - transferAmount;

      if (debtors[debtorId]! <= epsilon) i++;
      if (creditors[creditorId]! <= epsilon) j++;
    }

    return transfers;
  }
}
