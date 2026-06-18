import 'package:firebase_core/firebase_core.dart';
import 'package:share_app/data/auth_repository.dart';
import 'package:share_app/data/balances_repository.dart';
import 'package:share_app/data/expenses_repository.dart';
import 'package:share_app/data/groups_repository.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/repository/auth_repository_contract.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/usecase/add_expense_use_case.dart';
import 'package:share_app/domain/usecase/calculate_balances_use_case.dart';
import 'package:share_app/domain/usecase/create_group_use_case.dart';
import 'package:share_app/domain/usecase/delete_expense_use_case.dart';
import 'package:share_app/domain/usecase/edit_expense_use_case.dart';
import 'package:share_app/domain/usecase/get_balances_use_case.dart';
import 'package:share_app/domain/usecase/get_current_user_use_case.dart';
import 'package:share_app/domain/usecase/import_csv_use_case.dart';
import 'package:share_app/domain/usecase/join_group_use_case.dart';
import 'package:share_app/domain/usecase/settle_up_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_with_email_use_case.dart';
import 'package:share_app/domain/usecase/sign_in_with_google_use_case.dart';
import 'package:share_app/domain/usecase/sign_out_use_case.dart';
import 'package:share_app/domain/usecase/sign_up_with_email_use_case.dart';
import 'package:share_app/domain/usecase/watch_expenses_use_case.dart';
import 'package:share_app/domain/usecase/watch_groups_use_case.dart';
import 'package:share_app/domain/usecase/watch_settlements_use_case.dart';
import 'package:share_app/remote-data-source/firebase/auth_remote_datasource.dart';
import 'package:share_app/remote-data-source/firebase/firestore_remote_datasource.dart';

/// Punto único de inyección de dependencias (sin `get_it`/`riverpod`), igual
/// que en radiocom-flutter: aquí se instancian datasources, repositorios,
/// casos de uso y el [Invoker], y se exponen como getters para que cada
/// presenter los reciba en su constructor.
class DependencyInjector {
  DependencyInjector._();

  static final DependencyInjector instance = DependencyInjector._();

  final Invoker invoker = Invoker();

  late AuthRepositoryContract _authRepository;
  late GroupsRepositoryContract _groupsRepository;
  late ExpensesRepositoryContract _expensesRepository;
  late BalancesRepositoryContract _balancesRepository;

  /// Debe llamarse una vez al arrancar la app (antes de `runApp`), para
  /// inicializar Firebase y las dependencias que dependen de él.
  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _authRepository = AuthRepository(remoteDataSource: AuthRemoteDataSource());
    final firestoreDataSource = FirestoreRemoteDataSource();
    _groupsRepository = GroupsRepository(remoteDataSource: firestoreDataSource);
    _expensesRepository = ExpensesRepository(remoteDataSource: firestoreDataSource);
    _balancesRepository = BalancesRepository(remoteDataSource: firestoreDataSource);
  }

  AuthRepositoryContract get authRepository => _authRepository;

  GroupsRepositoryContract get groupsRepository => _groupsRepository;

  ExpensesRepositoryContract get expensesRepository => _expensesRepository;

  BalancesRepositoryContract get balancesRepository => _balancesRepository;

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

  // --- Casos de uso de grupos (Fase 2) ---
  CreateGroupUseCase get createGroupUseCase => CreateGroupUseCase(repository: groupsRepository);

  WatchGroupsUseCase get watchGroupsUseCase => WatchGroupsUseCase(repository: groupsRepository);

  JoinGroupUseCase get joinGroupUseCase => JoinGroupUseCase(repository: groupsRepository);

  // --- Casos de uso de gastos (Fase 3) ---
  WatchExpensesUseCase get watchExpensesUseCase =>
      WatchExpensesUseCase(repository: expensesRepository);

  AddExpenseUseCase get addExpenseUseCase => AddExpenseUseCase(repository: expensesRepository);

  EditExpenseUseCase get editExpenseUseCase => EditExpenseUseCase(repository: expensesRepository);

  DeleteExpenseUseCase get deleteExpenseUseCase =>
      DeleteExpenseUseCase(repository: expensesRepository);

  ImportCsvUseCase get importCsvUseCase => ImportCsvUseCase(repository: expensesRepository);

  // --- Casos de uso de balances/liquidaciones (Fase 4) ---
  GetBalancesUseCase get getBalancesUseCase => GetBalancesUseCase(repository: balancesRepository);

  CalculateBalancesUseCase get calculateBalancesUseCase =>
      CalculateBalancesUseCase(repository: balancesRepository);

  WatchSettlementsUseCase get watchSettlementsUseCase =>
      WatchSettlementsUseCase(repository: balancesRepository);

  SettleUpUseCase get settleUpUseCase => SettleUpUseCase(repository: balancesRepository);
}
