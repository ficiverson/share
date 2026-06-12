import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/get_current_user_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_with_email_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_with_google_use_case.dart';
import 'package:share_app/domain/usecase/sign_up_with_email_use_case.dart';
import 'package:share_app/models/user.dart';

/// Vista abstracta que implementa el widget `LoginView` de Flutter.
abstract class LoginViewContract {
  void onSessionRestored(AppUser user);
  void onNoSession();
  void onAuthLoading(bool isLoading);
  void onAuthSuccess(AppUser user);
  void onAuthError(String error);
}

class LoginPresenter {
  final LoginViewContract _view;
  final Invoker invoker;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithEmailUseCase signInWithEmailUseCase;
  final SignUpWithEmailUseCase signUpWithEmailUseCase;

  LoginPresenter(
    this._view, {
    required this.invoker,
    required this.getCurrentUserUseCase,
    required this.signInWithGoogleUseCase,
    required this.signInWithEmailUseCase,
    required this.signUpWithEmailUseCase,
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

  /// Lanza el flujo de Google Sign-In (vía Firebase Auth).
  void signInWithGoogle() {
    _view.onAuthLoading(true);
    invoker.execute(signInWithGoogleUseCase).listen((result) {
      _view.onAuthLoading(false);
      if (result is Success) {
        _view.onAuthSuccess(result.getData() as AppUser);
      } else {
        _view.onAuthError((result as Error).getError());
      }
    });
  }

  /// Inicia sesión con email y contraseña.
  void signInWithEmail(String email, String password) {
    _view.onAuthLoading(true);
    invoker
        .execute(signInWithEmailUseCase.withParams(
      SignInWithEmailParams(email: email, password: password),
    ))
        .listen((result) {
      _view.onAuthLoading(false);
      if (result is Success) {
        _view.onAuthSuccess(result.getData() as AppUser);
      } else {
        _view.onAuthError((result as Error).getError());
      }
    });
  }

  /// Crea una cuenta nueva con email y contraseña.
  void signUpWithEmail(String email, String password, String displayName) {
    _view.onAuthLoading(true);
    invoker
        .execute(signUpWithEmailUseCase.withParams(
      SignUpWithEmailParams(email: email, password: password, displayName: displayName),
    ))
        .listen((result) {
      _view.onAuthLoading(false);
      if (result is Success) {
        _view.onAuthSuccess(result.getData() as AppUser);
      } else {
        _view.onAuthError((result as Error).getError());
      }
    });
  }
}
