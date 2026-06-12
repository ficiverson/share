import 'package:share_app/data/datasource/auth_remote_datasource_contract.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/models/user.dart';

/// Implementación de [AuthRepositoryContract] sobre Firebase Auth. Firebase
/// gestiona la persistencia de sesión, así que no necesita un datasource
/// local propio.
class AuthRepository implements AuthRepositoryContract {
  final AuthRemoteDataSourceContract _remoteDataSource;

  AuthRepository({required AuthRemoteDataSourceContract remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<AppUser> signInWithGoogle() => _remoteDataSource.signInWithGoogle();

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _remoteDataSource.signInWithEmail(email, password);

  @override
  Future<AppUser> signUpWithEmail(String email, String password, String displayName) =>
      _remoteDataSource.signUpWithEmail(email, password, displayName);

  @override
  Future<void> signOut() => _remoteDataSource.signOut();

  @override
  AppUser? getCurrentUser() => _remoteDataSource.getCurrentUser();

  @override
  Stream<AppUser?> authStateChanges() => _remoteDataSource.authStateChanges();
}
