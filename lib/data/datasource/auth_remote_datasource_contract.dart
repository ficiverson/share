import 'package:share_app/models/user.dart';

/// Contrato del datasource remoto de autenticación: envuelve Firebase Auth
/// (incluyendo el flujo de credenciales de Google a través de `google_sign_in`).
abstract class AuthRemoteDataSourceContract {
  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithEmail(String email, String password);

  Future<AppUser> signUpWithEmail(String email, String password, String displayName);

  Future<void> updateDisplayName(String name);

  Future<void> signOut();

  AppUser? getCurrentUser();

  Stream<AppUser?> authStateChanges();
}
