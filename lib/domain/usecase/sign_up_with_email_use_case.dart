import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/user.dart';

/// Parámetros para crear una cuenta con email y contraseña.
class SignUpWithEmailParams {
  final String email;
  final String password;
  final String displayName;

  SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

/// Crea una cuenta nueva con email y contraseña (Firebase Auth).
class SignUpWithEmailUseCase extends BaseUseCase<SignUpWithEmailParams, AppUser> {
  final AuthRepositoryContract repository;

  SignUpWithEmailUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<AppUser>> _run() async {
    try {
      final p = params!;
      final user = await repository.signUpWithEmail(p.email, p.password, p.displayName);
      return Success(user, Status.ok);
    } catch (e) {
      return Error(AppUser(id: '', email: '', displayName: ''), Status.fail, e.toString());
    }
  }
}
