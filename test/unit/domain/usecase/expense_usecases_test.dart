import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/add_expense_use_case.dart';
import 'package:share_app/domain/usecase/delete_all_expenses_use_case.dart';
import 'package:share_app/domain/usecase/delete_expense_use_case.dart';
import 'package:share_app/domain/usecase/edit_expense_use_case.dart';
import 'package:share_app/domain/usecase/export_csv_use_case.dart';
import 'package:share_app/domain/usecase/watch_expenses_use_case.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/split.dart';

// ── In-memory expenses repo ───────────────────────────────────────────────────
class _FakeExpensesRepo implements ExpensesRepositoryContract {
  final List<Expense> _store = [];
  bool shouldThrow = false;

  @override
  Stream<List<Expense>> watchExpenses(String groupId) => Stream.value(List.unmodifiable(_store));

  @override
  Future<List<Expense>> getExpenses(String groupId) async => List.unmodifiable(_store);

  @override
  Future<Expense> addExpense(String groupId, Expense expense) async {
    if (shouldThrow) throw Exception('add failed');
    final saved = Expense(
      expenseId: 'eid_${_store.length + 1}',
      description: expense.description,
      amount: expense.amount,
      currency: expense.currency,
      category: expense.category,
      paidBy: expense.paidBy,
      date: expense.date,
      createdAt: expense.createdAt,
      splits: expense.splits,
    );
    _store.add(saved);
    return saved;
  }

  @override
  Future<Expense> editExpense(String groupId, Expense expense) async {
    if (shouldThrow) throw Exception('edit failed');
    final i = _store.indexWhere((e) => e.expenseId == expense.expenseId);
    if (i == -1) throw Exception('not found');
    _store[i] = expense;
    return expense;
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    if (shouldThrow) throw Exception('delete failed');
    _store.removeWhere((e) => e.expenseId == expenseId);
  }

  @override
  Future<int> deleteAllExpenses(String groupId) async {
    if (shouldThrow) throw Exception('deleteAll failed');
    final count = _store.length;
    _store.clear();
    return count;
  }

  @override
  String exportCsv(Group group, List<Expense> expenses) {
    if (shouldThrow) throw Exception('export failed');
    return 'header\nrow';
  }

  @override
  Future<int> importCsv(String groupId, String csvContent, {Map<String, String>? columnMapping}) async => 0;
}

// ── Fixture helpers ───────────────────────────────────────────────────────────
Expense _expense({String id = '', double amount = 60}) => Expense(
      expenseId: id,
      description: 'Cena',
      amount: amount,
      currency: 'EUR',
      category: 'Comida',
      paidBy: 'alice',
      date: DateTime(2024, 6, 15),
      createdAt: DateTime(2024, 6, 15),
      splits: [
        Split(memberId: 'alice', shareAmount: amount / 2, shareType: ShareType.equal),
        Split(memberId: 'bob', shareAmount: amount / 2, shareType: ShareType.equal),
      ],
    );

Group _group() {
  final alice = Member(memberId: 'alice', name: 'Alice', email: 'a@e.com', joinedAt: DateTime(2024), role: MemberRole.owner);
  final bob = Member(memberId: 'bob', name: 'Bob', email: 'b@e.com', joinedAt: DateTime(2024));
  return Group(groupId: 'g1', name: 'Grupo', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024), members: [alice, bob], memberIds: ['alice', 'bob']);
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  late _FakeExpensesRepo repo;
  late Invoker invoker;

  setUp(() {
    repo = _FakeExpensesRepo();
    invoker = Invoker();
  });

  group('AddExpenseUseCase', () {
    test('éxito devuelve Success con gasto con id', () async {
      final uc = AddExpenseUseCase(repository: repo)
        ..params = AddExpenseParams(groupId: 'g1', expense: _expense());
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect((results.first.data as Expense).expenseId, isNotEmpty);
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = AddExpenseUseCase(repository: repo)
        ..params = AddExpenseParams(groupId: 'g1', expense: _expense());
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
      expect((results.first as Error).getError(), contains('add failed'));
    });
  });

  group('EditExpenseUseCase', () {
    test('éxito devuelve Success con gasto actualizado', () async {
      repo._store.add(_expense(id: 'e1'));
      final edited = Expense(expenseId: 'e1', description: 'Editado', amount: 60, currency: 'EUR', category: '', paidBy: 'alice', date: DateTime(2024), createdAt: DateTime(2024), splits: []);
      final uc = EditExpenseUseCase(repository: repo)
        ..params = EditExpenseParams(groupId: 'g1', expense: edited);
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect((results.first.data as Expense).description, 'Editado');
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = EditExpenseUseCase(repository: repo)
        ..params = EditExpenseParams(groupId: 'g1', expense: _expense(id: 'e1'));
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('DeleteExpenseUseCase', () {
    test('éxito devuelve Success y elimina el gasto', () async {
      repo._store.add(_expense(id: 'e1'));
      final uc = DeleteExpenseUseCase(repository: repo)
        ..params = DeleteExpenseParams(groupId: 'g1', expenseId: 'e1');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect(repo._store, isEmpty);
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = DeleteExpenseUseCase(repository: repo)
        ..params = DeleteExpenseParams(groupId: 'g1', expenseId: 'e1');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('DeleteAllExpensesUseCase', () {
    test('borra todos y devuelve el count', () async {
      repo._store.addAll([_expense(id: 'e1'), _expense(id: 'e2')]);
      final uc = DeleteAllExpensesUseCase(repository: repo)..params = 'g1';
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect(results.first.data, 2);
      expect(repo._store, isEmpty);
    });
  });

  group('WatchExpensesUseCase', () {
    test('watch devuelve stream con gastos', () async {
      repo._store.add(_expense(id: 'e1'));
      final uc = WatchExpensesUseCase(repository: repo);
      final list = await uc.watch('g1').first;
      expect(list.length, 1);
      expect(list.first.description, 'Cena');
    });
  });

  group('ExportCsvUseCase', () {
    test('éxito devuelve Success con csv no vacío', () async {
      final uc = ExportCsvUseCase(repository: repo)
        ..params = ExportCsvParams(group: _group(), expenses: [_expense(id: 'e1')]);
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect(results.first.data, isNotEmpty);
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = ExportCsvUseCase(repository: repo)
        ..params = ExportCsvParams(group: _group(), expenses: []);
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });
}
