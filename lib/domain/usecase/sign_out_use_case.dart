import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

/// Cierra la sesión del usuario actual.
class SignOutUseCase extends BaseUseCase<void, void> {
  final AuthRepositoryContract repository;

  SignOutUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<void>> _run() async {
    try {
      await repository.signOut();
      return Success(null, Status.ok);
    } catch (e) {
      return Error(null, Status.fail, e.toString());
    }
  }
}
