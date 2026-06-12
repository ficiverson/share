import 'package:hive/hive.dart';
import 'package:share_app/data/datasource/auth_local_datasource_contract.dart';
import 'package:share_app/models/user.dart';

/// Implementación basada en Hive de [AuthLocalDataSourceContract].
/// Cachea el usuario autenticado como un `Map` dentro de la box `auth`.
class AuthLocalDataSource implements AuthLocalDataSourceContract {
  static const String boxName = 'auth';
  static const String userKey = 'current_user';

  final Box box;

  AuthLocalDataSource({required this.box});

  @override
  Future<void> saveUser(AppUser user) async {
    await box.put(userKey, user.toJson());
  }

  @override
  AppUser? getUser() {
    final data = box.get(userKey);
    if (data == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> clearUser() async {
    await box.delete(userKey);
  }
}
