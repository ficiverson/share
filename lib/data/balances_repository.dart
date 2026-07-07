import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/models/balance.dart';
import 'package:share_app/models/settlement.dart';

/// Implementación de [BalancesRepositoryContract] sobre Cloud Firestore. Los
/// balances no se persisten: se calculan en cliente a partir de los gastos
/// (`expenses` + `splits`) y las liquidaciones (`settlements`) del grupo.
class BalancesRepository implements BalancesRepositoryContract {
  final FirestoreRemoteDataSourceContract _remoteDataSource;

  BalancesRepository({required FirestoreRemoteDataSourceContract remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<MemberBalance>> getBalances(String groupId) async {
    final group = await _remoteDataSource.watchGroup(groupId).first;
    final expenses = await _remoteDataSource.getExpenses(groupId);
    final settlements = await _remoteDataSource.watchSettlements(groupId).first;

    final paid = <String, double>{};
    final owed = <String, double>{};

    // Incluye a todos los miembros del grupo, aunque no tengan gastos.
    for (final member in group.members) {
      paid[member.memberId] = 0;
      owed[member.memberId] = 0;
    }

    for (final expense in expenses) {
      // Pago único o compartido entre varios pagadores
      if (expense.payments.isNotEmpty) {
        for (final payment in expense.payments) {
          paid[payment.memberId] = (paid[payment.memberId] ?? 0) + payment.shareAmount;
        }
      } else {
        paid[expense.paidBy] = (paid[expense.paidBy] ?? 0) + expense.amount;
      }
      for (final split in expense.splits) {
        owed[split.memberId] = (owed[split.memberId] ?? 0) + split.shareAmount;
      }
    }

    // Una liquidación de `from` a `to` por `amount` significa que `from` ha
    // pagado su deuda: aumenta su "paid". `to` ha recibido ese pago: aumenta
    // su "owed" (su saldo a favor se reduce en la misma cantidad).
    for (final settlement in settlements) {
      paid[settlement.fromMemberId] = (paid[settlement.fromMemberId] ?? 0) + settlement.amount;
      owed[settlement.toMemberId] = (owed[settlement.toMemberId] ?? 0) + settlement.amount;
    }

    final memberIds = <String>{...paid.keys, ...owed.keys};
    return memberIds
        .map((memberId) => MemberBalance(
              memberId: memberId,
              paid: paid[memberId] ?? 0,
              owed: owed[memberId] ?? 0,
            ))
        .toList();
  }

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) =>
      _remoteDataSource.watchSettlements(groupId);

  @override
  Future<Settlement> settleUp(String groupId, Settlement settlement) =>
      _remoteDataSource.addSettlement(groupId, settlement);
}
