import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/user.dart';

/// Intenta restaurar la sesión (silent sign-in) y devuelve el usuario actual,
/// o `null` si no hay ninguna sesión.
class GetCurrentUserUseCase extends BaseUseCase<void, AppUser?> {
  final AuthRepositoryContract repository;

  GetCurrentUserUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<AppUser?>> _run() async {
    try {
      final user = await repository.restoreSession();
      return Success(user, Status.ok);
    } catch (e) {
      return Error(null, Status.fail, e.toString());
    }
  }
}
