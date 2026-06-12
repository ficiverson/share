import 'package:share_app/models/user.dart';

/// Contrato del datasource remoto de autenticación: envuelve `google_sign_in`
/// y expone el usuario de Google y las cabeceras autenticadas para llamar a
/// las APIs de Drive/Sheets.
abstract class AuthRemoteDataSourceContract {
  Future<AppUser> signIn();

  Future<AppUser?> signInSilently();

  Future<void> signOut();

  Future<Map<String, String>> getAuthHeaders();
}
