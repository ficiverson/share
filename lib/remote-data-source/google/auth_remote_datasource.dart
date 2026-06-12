import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_app/data/datasource/auth_remote_datasource_contract.dart';
import 'package:share_app/models/user.dart';

/// Wrapper de `google_sign_in`. Scopes necesarios: identidad (email, profile)
/// + acceso a los archivos creados por la app en Drive + Sheets.
class AuthRemoteDataSource implements AuthRemoteDataSourceContract {
  static const List<String> scopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/spreadsheets',
  ];

  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: scopes);

  AppUser _toAppUser(GoogleSignInAccount account) => AppUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? account.email,
        photoUrl: account.photoUrl,
      );

  @override
  Future<AppUser> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Inicio de sesión cancelado por el usuario');
    }
    return _toAppUser(account);
  }

  @override
  Future<AppUser?> signInSilently() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) return null;
    return _toAppUser(account);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  @override
  Future<Map<String, String>> getAuthHeaders() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      throw Exception('No hay sesión activa de Google');
    }
    return account.authHeaders;
  }
}
