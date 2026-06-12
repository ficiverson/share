import 'package:share_app/models/user.dart';

/// Contrato del repositorio de autenticación. Implementado por
/// `AuthRepository` en `data/`, que combina el datasource local (sesión
/// cacheada) con el remoto (`google_sign_in`).
abstract class AuthRepositoryContract {
  /// Lanza el flujo de Google Sign-In. Devuelve el usuario autenticado.
  Future<AppUser> signIn();

  /// Cierra la sesión actual (Google + caché local).
  Future<void> signOut();

  /// Devuelve el usuario cacheado, o `null` si no hay sesión activa.
  AppUser? getCurrentUser();

  /// Intenta restaurar una sesión previa (silent sign-in) al iniciar la app.
  Future<AppUser?> restoreSession();

  /// Cabeceras HTTP autenticadas (Bearer token) para llamar a las APIs de
  /// Google Drive/Sheets.
  Future<Map<String, String>> getAuthHeaders();
}
