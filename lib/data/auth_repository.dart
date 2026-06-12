import 'package:share_app/data/datasource/auth_local_datasource_contract.dart';
import 'package:share_app/data/datasource/auth_remote_datasource_contract.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/models/user.dart';

/// Implementación de [AuthRepositoryContract]: delega el login en
/// [AuthRemoteDataSourceContract] (Google Sign-In) y cachea el usuario en
/// [AuthLocalDataSourceContract].
class AuthRepository implements AuthRepositoryContract {
  final AuthLocalDataSourceContract _localDataSource;
  final AuthRemoteDataSourceContract _remoteDataSource;

  AuthRepository({
    required AuthLocalDataSourceContract localDataSource,
    required AuthRemoteDataSourceContract remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<AppUser> signIn() async {
    final user = await _remoteDataSource.signIn();
    await _localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
    await _localDataSource.clearUser();
  }

  @override
  AppUser? getCurrentUser() => _localDataSource.getUser();

  @override
  Future<AppUser?> restoreSession() async {
    final user = await _remoteDataSource.signInSilently();
    if (user != null) {
      await _localDataSource.saveUser(user);
      return user;
    }
    return _localDataSource.getUser();
  }

  @override
  Future<Map<String, String>> getAuthHeaders() => _remoteDataSource.getAuthHeaders();
}
