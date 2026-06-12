import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/user.dart';

/// Parámetros para iniciar sesión con email y contraseña.
class SignInWithEmailParams {
  final String email;
  final String password;

  SignInWithEmailParams({required this.email, required this.password});
}

/// Inicia sesión con email y contraseña (Firebase Auth).
class SignInWithEmailUseCase extends BaseUseCase<SignInWithEmailParams, AppUser> {
  final AuthRepositoryContract repository;

  SignInWithEmailUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<AppUser>> _run() async {
    try {
      final p = params!;
      final user = await repository.signInWithEmail(p.email, p.password);
      return Success(user, Status.ok);
    } catch (e) {
      return Error(AppUser(id: '', email: '', displayName: ''), Status.fail, e.toString());
    }
  }
}
