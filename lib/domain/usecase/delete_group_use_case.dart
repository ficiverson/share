import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

/// Borra el grupo (gastos + liquidaciones + documento). Solo debe llamarse
/// si el usuario es el creador del grupo.
class DeleteGroupUseCase extends BaseUseCase<String, void> {
  final GroupsRepositoryContract repository;

  DeleteGroupUseCase({required this.repository});

  @override
  void invoke() => notifyListeners(_run());

  Future<Result<void>> _run() async {
    try {
      await repository.deleteGroup(params!);
      return Success(null, Status.ok);
    } catch (e) {
      return Error(null, Status.fail, e.toString());
    }
  }
}
