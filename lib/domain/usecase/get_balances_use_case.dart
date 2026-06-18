import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/balance.dart';

/// Devuelve el balance neto (pagado - debido) de cada miembro del grupo,
/// calculado a partir de gastos + repartos + liquidaciones.
class GetBalancesUseCase extends BaseUseCase<String, List<MemberBalance>> {
  final BalancesRepositoryContract repository;

  GetBalancesUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<List<MemberBalance>>> _run() async {
    try {
      final groupId = params!;
      final balances = await repository.getBalances(groupId);
      return Success(balances, Status.ok);
    } catch (e) {
      return Error(<MemberBalance>[], Status.fail, e.toString());
    }
  }
}
