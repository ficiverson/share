import 'package:share_app/models/user.dart';

/// Contrato del repositorio de autenticación, respaldado por Firebase Auth.
abstract class AuthRepositoryContract {
  /// Inicia sesión con Google (vía `google_sign_in`, las credenciales se
  /// pasan a Firebase Auth).
  Future<AppUser> signInWithGoogle();

  /// Inicia sesión con email y contraseña.
  Future<AppUser> signInWithEmail(String email, String password);

  /// Crea una cuenta nueva con email y contraseña.
  Future<AppUser> signUpWithEmail(String email, String password, String displayName);

  /// Cierra la sesión actual.
  Future<void> signOut();

  /// Usuario actualmente autenticado (sincrónico), o `null` si no hay sesión.
  AppUser? getCurrentUser();

  /// Stream con los cambios de sesión (login/logout), emitido por Firebase Auth.
  Stream<AppUser?> authStateChanges();
}
