import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/group.dart';

/// Parámetros para crear un grupo nuevo.
class CreateGroupParams {
  final String name;
  final String currency;
  final String createdByUid;
  final String createdByName;
  final String createdByEmail;
  final String? createdByPhotoUrl;

  CreateGroupParams({
    required this.name,
    required this.currency,
    required this.createdByUid,
    required this.createdByName,
    required this.createdByEmail,
    this.createdByPhotoUrl,
  });
}

/// Crea un nuevo grupo en Firestore con el usuario actual como único miembro.
class CreateGroupUseCase extends BaseUseCase<CreateGroupParams, Group> {
  final GroupsRepositoryContract repository;

  CreateGroupUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<Group>> _run() async {
    try {
      final p = params!;
      final group = await repository.createGroup(
        name: p.name,
        currency: p.currency,
        createdByUid: p.createdByUid,
        createdByName: p.createdByName,
        createdByEmail: p.createdByEmail,
        createdByPhotoUrl: p.createdByPhotoUrl,
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
