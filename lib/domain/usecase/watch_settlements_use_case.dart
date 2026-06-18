import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/models/settlement.dart';

/// Expone en tiempo real las liquidaciones de un grupo. Se usa a través de
/// [watch], no del [Invoker] (igual que [WatchGroupsUseCase] /
/// [WatchExpensesUseCase]).
class WatchSettlementsUseCase extends BaseUseCase<String, List<Settlement>> {
  final BalancesRepositoryContract repository;

  WatchSettlementsUseCase({required this.repository});

  @override
  void invoke() {
    // No-op: ver [watch].
  }

  Stream<List<Settlement>> watch(String groupId) => repository.watchSettlements(groupId);
}
