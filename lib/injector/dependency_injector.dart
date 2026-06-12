import 'package:firebase_core/firebase_core.dart';
import 'package:share_app/data/auth_repository.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/usecase/get_current_user_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_with_email_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_with_google_use_case.dart';
import 'package:share_app/domain/usecase/sign_out_use_case.dart';
import 'package:share_app/domain/usecase/sign_up_with_email_use_case.dart';
import 'package:share_app/remote-data-source/firebase/auth_remote_datasource.dart';

/// Punto único de inyección de dependencias (sin `get_it`/`riverpod`), igual
/// que en radiocom-flutter: aquí se instancian datasources, repositorios,
/// casos de uso y el [Invoker], y se exponen como getters para que cada
/// presenter los reciba en su constructor.
class DependencyInjector {
  DependencyInjector._();

  static final DependencyInjector instance = DependencyInjector._();

  final Invoker invoker = Invoker();

  late AuthRepositoryContract _authRepository;

  /// Debe llamarse una vez al arrancar la app (antes de `runApp`), para
  /// inicializar Firebase y las dependencias que dependen de él.
  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _authRepository = AuthRepository(remoteDataSource: AuthRemoteDataSource());
  }

  AuthRepositoryContract get authRepository => _authRepository;

  // --- Casos de uso de autenticación ---
  SignInWithGoogleUseCase get signInWithGoogleUseCase =>
      SignInWithGoogleUseCase(repository: authRepository);

  SignInWithEmailUseCase get signInWithEmailUseCase =>
      SignInWithEmailUseCase(repository: authRepository);

  SignUpWithEmailUseCase get signUpWithEmailUseCase =>
      SignUpWithEmailUseCase(repository: authRepository);

  SignOutUseCase get signOutUseCase => SignOutUseCase(repository: authRepository);

  GetCurrentUserUseCase get getCurrentUserUseCase =>
      GetCurrentUserUseCase(repository: authRepository);
}
