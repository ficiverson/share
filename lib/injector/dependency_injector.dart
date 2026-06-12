import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_app/data/auth_repository.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/usecase/get_current_user_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_use_case.dart';
import 'package:share_app/domain/usecase/sign_out_use_case.dart';
import 'package:share_app/local-data-source/auth_local_datasource.dart';
import 'package:share_app/remote-data-source/google/auth_remote_datasource.dart';

/// Punto único de inyección de dependencias (sin `get_it`/`riverpod`), igual
/// que en radiocom-flutter: aquí se instancian datasources, repositorios,
/// casos de uso y el [Invoker], y se exponen como getters para que cada
/// presenter los reciba en su constructor.
class DependencyInjector {
  DependencyInjector._();

  static final DependencyInjector instance = DependencyInjector._();

  late Box _authBox;

  final Invoker invoker = Invoker();

  late AuthRepositoryContract _authRepository;

  /// Debe llamarse una vez al arrancar la app (antes de `runApp`), para
  /// inicializar Hive y abrir las boxes necesarias.
  Future<void> init() async {
    await Hive.initFlutter();
    _authBox = await Hive.openBox(AuthLocalDataSource.boxName);

    _authRepository = AuthRepository(
      localDataSource: AuthLocalDataSource(box: _authBox),
      remoteDataSource: AuthRemoteDataSource(),
    );
  }

  AuthRepositoryContract get authRepository => _authRepository;

  // --- Casos de uso de autenticación ---
  SignInUseCase get signInUseCase => SignInUseCase(repository: authRepository);

  SignOutUseCase get signOutUseCase => SignOutUseCase(repository: authRepository);

  GetCurrentUserUseCase get getCurrentUserUseCase =>
      GetCurrentUserUseCase(repository: authRepository);
}
