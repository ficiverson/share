import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/get_current_user_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_use_case.dart';
import 'package:share_app/models/user.dart';

/// Vista abstracta que implementa el widget `LoginView` de Flutter.
abstract class LoginViewContract {
  void onSessionRestored(AppUser user);
  void onNoSession();
  void onSignInLoading(bool isLoading);
  void onSignInSuccess(AppUser user);
  void onSignInError(String error);
}

class LoginPresenter {
  final LoginViewContract _view;
  final Invoker invoker;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SignInUseCase signInUseCase;

  LoginPresenter(
    this._view, {
    required this.invoker,
    required this.getCurrentUserUseCase,
    required this.signInUseCase,
  });

  /// Comprueba al arrancar la pantalla si ya hay una sesión activa.
  void checkSession() {
    invoker.execute(getCurrentUserUseCase).listen((result) {
      if (result is Success && result.getData() != null) {
        _view.onSessionRestored(result.getData() as AppUser);
      } else {
        _view.onNoSession();
      }
    });
  }

  /// Lanza el flujo de Google Sign-In.
  void signIn() {
    _view.onSignInLoading(true);
    invoker.execute(signInUseCase).listen((result) {
      _view.onSignInLoading(false);
      if (result is Success) {
        _view.onSignInSuccess(result.getData() as AppUser);
      } else {
        _view.onSignInError((result as Error).getError());
      }
    });
  }
}
