import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/group.dart';

/// Parámetros para unirse a un grupo existente mediante su `groupId`.
class JoinGroupParams {
  final String groupId;
  final String memberUid;
  final String memberName;
  final String memberEmail;
  final String? memberPhotoUrl;

  JoinGroupParams({
    required this.groupId,
    required this.memberUid,
    required this.memberName,
    required this.memberEmail,
    this.memberPhotoUrl,
  });
}

/// Añade al usuario actual como miembro de un grupo existente.
class JoinGroupUseCase extends BaseUseCase<JoinGroupParams, Group> {
  final GroupsRepositoryContract repository;

  JoinGroupUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<Group>> _run() async {
    try {
      final p = params!;
      final group = await repository.joinGroup(
        groupId: p.groupId,
        memberUid: p.memberUid,
        memberName: p.memberName,
        memberEmail: p.memberEmail,
        memberPhotoUrl: p.memberPhotoUrl,
      );
      return Success(group, Status.ok);
    } catch (e) {
      return Error(
        Group(groupId: '', name: '', currency: '', createdBy: '', createdAt: DateTime.now()),
        Status.fail,
        e.toString(),
      );
    }
  }
}
