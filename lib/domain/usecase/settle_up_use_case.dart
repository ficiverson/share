import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/settlement.dart';

/// Parámetros para registrar una liquidación entre dos miembros.
class SettleUpParams {
  final String groupId;
  final Settlement settlement;

  SettleUpParams({required this.groupId, required this.settlement});
}

class SettleUpUseCase extends BaseUseCase<SettleUpParams, Settlement> {
  final BalancesRepositoryContract repository;

  SettleUpUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<Settlement>> _run() async {
    try {
      final p = params!;
      final settlement = await repository.settleUp(p.groupId, p.settlement);
      return Success(settlement, Status.ok);
    } catch (e) {
      return Error(params!.settlement, Status.fail, e.toString());
    }
  }
}
