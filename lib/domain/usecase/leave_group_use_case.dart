import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

/// Parámetros para salir de un grupo.
class LeaveGroupParams {
  final String groupId;
  final String uid;

  LeaveGroupParams({required this.groupId, required this.uid});
}

/// Elimina al usuario actual del grupo (de `memberIds` y del mapa `members`).
class LeaveGroupUseCase extends BaseUseCase<LeaveGroupParams, void> {
  final GroupsRepositoryContract repository;

  LeaveGroupUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<void>> _run() async {
    try {
      final p = params!;
      await repository.leaveGroup(p.groupId, p.uid);
      return Success(null, Status.ok);
    } catch (e) {
      return Error(null, Status.fail, e.toString());
    }
  }
}
