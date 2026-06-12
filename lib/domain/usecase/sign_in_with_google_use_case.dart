import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/user.dart';

/// Lanza el flujo de inicio de sesión con Google (Firebase Auth).
class SignInWithGoogleUseCase extends BaseUseCase<void, AppUser> {
  final AuthRepositoryContract repository;

  SignInWithGoogleUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<AppUser>> _run() async {
    try {
      final user = await repository.signInWithGoogle();
      return Success(user, Status.ok);
    } catch (e) {
      return Error(AppUser(id: '', email: '', displayName: ''), Status.fail, e.toString());
    }
  }
}
