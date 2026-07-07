import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/data/balances_repository.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/data/expenses_repository.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/add_expense_use_case.dart';
import 'package:share_app/domain/usecase/delete_expense_use_case.dart';
import 'package:share_app/domain/usecase/edit_expense_use_case.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';
import 'package:share_app/models/split.dart';

// ── In-memory fake datasource ────────────────────────────────────────────────

class InMemoryDataSource implements FirestoreRemoteDataSourceContract {
  final Group group;
  final List<Expense> _expenses = [];
  final List<Settlement> _settlements = [];

  InMemoryDataSource({required this.group});

  @override
  Stream<Group> watchGroup(String groupId) => Stream.value(group);

  @override
  Future<List<Expense>> getExpenses(String groupId) async => List.unmodifiable(_expenses);

  @override
  Stream<List<Expense>> watchExpenses(String groupId) => Stream.value(List.unmodifiable(_expenses));

  @override
  Future<Expense> addExpense(String groupId, Expense expense) async {
    final saved = Expense(
      expenseId: 'exp_${_expenses.length + 1}',
      description: expense.description,
      amount: expense.amount,
      currency: expense.currency,
      category: expense.category,
      paidBy: expense.paidBy,
      createdBy: expense.createdBy,
      date: expense.date,
      createdAt: expense.createdAt,
      notes: expense.notes,
      splits: expense.splits,
    );
    _expenses.add(saved);
    return saved;
  }

  @override
  Future<Expense> updateExpense(String groupId, Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.expenseId == expense.expenseId);
    if (idx == -1) throw Exception('Expense not found');
    _expenses[idx] = expense;
    return expense;
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    _expenses.removeWhere((e) => e.expenseId == expenseId);
  }

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) =>
      Stream.value(List.unmodifiable(_settlements));

  @override
  Future<Settlement> addSettlement(String groupId, Settlement settlement) async {
    _settlements.add(settlement);
    return settlement;
  }

  // Métodos no necesarios para estos tests
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

// ── Fixtures ─────────────────────────────────────────────────────────────────

Group makeGroup() {
  final alice = Member(memberId: 'alice', name: 'Alice', email: 'a@e.com',
      joinedAt: DateTime(2024, 1, 1), role: MemberRole.owner);
  final bob = Member(memberId: 'bob', name: 'Bob', email: 'b@e.com',
      joinedAt: DateTime(2024, 1, 1));
  return Group(
    groupId: 'g1', name: 'Test Group', currency: 'EUR',
    createdBy: 'alice', createdAt: DateTime(2024, 1, 1),
    memberIds: ['alice', 'bob'], members: [alice, bob],
  );
}

Expense makeExpense({String id = '', double amount = 60}) => Expense(
      expenseId: id,
      description: 'Cena',
      amount: amount,
      currency: 'EUR',
      category: 'Comida',
      paidBy: 'alice',
      createdBy: 'alice',
      date: DateTime(2024, 6, 15),
      createdAt: DateTime(2024, 6, 15),
      splits: [
        Split(memberId: 'alice', shareAmount: amount / 2, shareType: ShareType.equal),
        Split(memberId: 'bob', shareAmount: amount / 2, shareType: ShareType.equal),
      ],
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late InMemoryDataSource ds;
  late ExpensesRepository expensesRepo;
  late BalancesRepository balancesRepo;

  setUp(() {
    ds = InMemoryDataSource(group: makeGroup());
    expensesRepo = ExpensesRepository(remoteDataSource: ds);
    balancesRepo = BalancesRepository(remoteDataSource: ds);
  });

  group('Flujo completo: añadir → editar → borrar gasto', () {
    test('AddExpenseUseCase guarda el gasto y lo devuelve con id', () async {
      final useCase = AddExpenseUseCase(repository: expensesRepo)
        ..params = AddExpenseParams(groupId: 'g1', expense: makeExpense());
      useCase.invoke();
      final result = await useCase.callback.getTasks().first;
      expect(result, isA<Success>());
      final saved = (result as Success).data as Expense;
      expect(saved.expenseId, isNotEmpty);
      expect(saved.description, 'Cena');
    });

    test('Después de add, getExpenses devuelve el gasto', () async {
      final useCase = AddExpenseUseCase(repository: expensesRepo)
        ..params = AddExpenseParams(groupId: 'g1', expense: makeExpense());
      useCase.invoke();
      await useCase.callback.getTasks().first;

      final expenses = await expensesRepo.getExpenses('g1');
      expect(expenses.length, 1);
      expect(expenses.first.description, 'Cena');
    });

    test('EditExpenseUseCase actualiza el gasto existente', () async {
      // Añadir
      final addUC = AddExpenseUseCase(repository: expensesRepo)
        ..params = AddExpenseParams(groupId: 'g1', expense: makeExpense());
      addUC.invoke();
      final addResult = await addUC.callback.getTasks().first;
      final saved = (addResult as Success).data as Expense;

      // Editar
      final edited = Expense(
        expenseId: saved.expenseId,
        description: 'Cena editada',
        amount: saved.amount,
        currency: saved.currency,
        category: saved.category,
        paidBy: saved.paidBy,
        date: saved.date,
        createdAt: saved.createdAt,
        splits: saved.splits,
      );
      final editUC = EditExpenseUseCase(repository: expensesRepo)
        ..params = EditExpenseParams(groupId: 'g1', expense: edited);
      editUC.invoke();
      final editResult = await editUC.callback.getTasks().first;
      expect(editResult, isA<Success>());

      final expenses = await expensesRepo.getExpenses('g1');
      expect(expenses.first.description, 'Cena editada');
    });

    test('DeleteExpenseUseCase elimina el gasto', () async {
      final addUC = AddExpenseUseCase(repository: expensesRepo)
        ..params = AddExpenseParams(groupId: 'g1', expense: makeExpense());
      addUC.invoke();
      final addResult = await addUC.callback.getTasks().first;
      final saved = (addResult as Success).data as Expense;

      final deleteUC = DeleteExpenseUseCase(repository: expensesRepo)
        ..params = DeleteExpenseParams(groupId: 'g1', expenseId: saved.expenseId);
      deleteUC.invoke();
      await deleteUC.callback.getTasks().first;

      final expenses = await expensesRepo.getExpenses('g1');
      expect(expenses, isEmpty);
    });
  });

  group('Flujo de balance: añadir gasto → calcular balance → liquidar', () {
    test('Balance correcto después de un gasto', () async {
      // Añadir gasto 60 EUR, Alice paga, reparto igual
      ds._expenses.add(makeExpense(id: 'e1', amount: 60));

      final balances = await balancesRepo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');

      expect(alice.netAmount, closeTo(30, 0.01));
      expect(bob.netAmount, closeTo(-30, 0.01));
    });

    test('Balance neutro después de liquidar', () async {
      ds._expenses.add(makeExpense(id: 'e1', amount: 60));

      // Bob liquida su deuda de 30 a Alice
      await balancesRepo.settleUp(
        'g1',
        Settlement(
          settlementId: 's1',
          fromMemberId: 'bob',
          toMemberId: 'alice',
          amount: 30,
          date: DateTime(2024, 6, 16),
          currency: 'EUR',
        ),
      );

      final balances = await balancesRepo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');

      expect(alice.netAmount, closeTo(0, 0.01));
      expect(bob.netAmount, closeTo(0, 0.01));
    });
  });
}
