import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/balance.dart';

/// Parámetros para obtener el balance de un único miembro.
class GetUserBalanceParams {
  final String groupId;
  final String uid;

  GetUserBalanceParams({required this.groupId, required this.uid});
}

/// Devuelve el balance neto (pagado − debido) del usuario actual en un grupo,
/// teniendo en cuenta gastos con múltiples pagadores y liquidaciones.
class GetUserBalanceUseCase
    extends BaseUseCase<GetUserBalanceParams, MemberBalance> {
  final BalancesRepositoryContract repository;

  GetUserBalanceUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<MemberBalance>> _run() async {
    try {
      final p = params!;
      final balance = await repository.getUserBalance(p.groupId, p.uid);
      return Success(balance, Status.ok);
    } catch (e) {
      return Error(
        MemberBalance(memberId: '', paid: 0, owed: 0),
        Status.fail,
        e.toString(),
      );
    }
  }
}
