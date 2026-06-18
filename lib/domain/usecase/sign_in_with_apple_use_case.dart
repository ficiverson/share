import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/user.dart';

/// Lanza el flujo de inicio de sesión con Apple ID (Firebase Auth).
class SignInWithAppleUseCase extends BaseUseCase<void, AppUser> {
  final AuthRepositoryContract repository;

  SignInWithAppleUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<AppUser>> _run() async {
    try {
      final user = await repository.signInWithApple();
      return Success(user, Status.ok);
    } catch (e) {
      return Error(AppUser(id: '', email: '', displayName: ''), Status.fail, e.toString());
    }
  }
}
