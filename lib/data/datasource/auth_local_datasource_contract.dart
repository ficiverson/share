import 'package:share_app/models/user.dart';

/// Contrato del datasource local de autenticación: cachea el usuario de la
/// sesión actual (p.ej. en Hive) para no depender de red en cada arranque.
abstract class AuthLocalDataSourceContract {
  Future<void> saveUser(AppUser user);

  AppUser? getUser();

  Future<void> clearUser();
}
