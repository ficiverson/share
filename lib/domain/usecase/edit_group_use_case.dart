import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

class EditGroupParams {
  final String groupId;
  final String name;
  final String currency;

  EditGroupParams({required this.groupId, required this.name, required this.currency});
}

/// Actualiza el nombre y la moneda de un grupo existente.
class EditGroupUseCase extends BaseUseCase<EditGroupParams, void> {
  final GroupsRepositoryContract repository;

  EditGroupUseCase({required this.repository});

  @override
  void invoke() => notifyListeners(_run());

  Future<Result<void>> _run() async {
    try {
      final p = params!;
      await repository.updateGroup(p.groupId, name: p.name, currency: p.currency);
      return Success(null, Status.ok);
    } catch (e) {
      return Error(null, Status.fail, e.toString());
    }
  }
}
