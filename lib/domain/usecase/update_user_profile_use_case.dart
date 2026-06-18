import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

class UpdateUserProfileParams {
  final String uid;
  final String name;

  UpdateUserProfileParams({required this.uid, required this.name});
}

/// Actualiza el nombre de usuario en Firebase Auth y en todos los grupos en
/// los que el usuario participa (campo `members.<uid>.name`).
class UpdateUserProfileUseCase extends BaseUseCase<UpdateUserProfileParams, void> {
  final AuthRepositoryContract authRepository;
  final GroupsRepositoryContract groupsRepository;

  UpdateUserProfileUseCase({
    required this.authRepository,
    required this.groupsRepository,
  });

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<void>> _run() async {
    try {
      final p = params!;
      await authRepository.updateDisplayName(p.name);
      await groupsRepository.updateUserNameInAllGroups(p.uid, p.name);
      return Success(null, Status.ok);
    } catch (e) {
      return Error(null, Status.fail, e.toString());
    }
  }
}
