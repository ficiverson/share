import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/data/expenses_repository.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';
import 'package:share_app/models/split.dart';

// ── In-memory datasource ──────────────────────────────────────────────────────
class _FakeDS implements FirestoreRemoteDataSourceContract {
  final List<Group> _groups = [];
  final Map<String, List<Expense>> _expenses = {};
  final Map<String, List<Settlement>> _settlements = {};

  void seedGroup(Group g) => _groups.add(g);

  @override Stream<List<Group>> watchGroups(String uid) => Stream.value(_groups.where((g) => g.memberIds.contains(uid)).toList());
  @override Future<List<Group>> getGroups(String uid) async => _groups.where((g) => g.memberIds.contains(uid)).toList();
  @override Stream<Group> watchGroup(String groupId) => Stream.value(_groups.firstWhere((g) => g.groupId == groupId));
  @override Future<Group> createGroup(Group group) async { _groups.add(group); return group; }
  @override Future<Group> addMember(String groupId, Member member) async { throw UnimplementedError(); }
  @override Future<void> leaveGroup(String groupId, String uid) async {}
  @override Future<void> updateMemberName(String groupId, String uid, String name) async {}
  @override Future<void> updateGroup(String groupId, {required String name, required String currency}) async {}
  @override Future<void> deleteGroup(String groupId) async {}

  @override
  Stream<List<Expense>> watchExpenses(String groupId) =>
      Stream.value(List.unmodifiable(_expenses[groupId] ?? []));

  @override
  Future<List<Expense>> getExpenses(String groupId) async =>
      List.unmodifiable(_expenses[groupId] ?? []);

  @override
  Future<Expense> addExpense(String groupId, Expense expense) async {
    final saved = Expense(
      expenseId: 'eid_${(_expenses[groupId]?.length ?? 0) + 1}',
      description: expense.description, amount: expense.amount,
      currency: expense.currency, category: expense.category,
      paidBy: expense.paidBy, date: expense.date, createdAt: expense.createdAt,
      splits: expense.splits,
    );
    _expenses.putIfAbsent(groupId, () => []).add(saved);
    return saved;
  }

  @override
  Future<Expense> updateExpense(String groupId, Expense expense) async {
    final list = _expenses[groupId] ?? [];
    final i = list.indexWhere((e) => e.expenseId == expense.expenseId);
    if (i >= 0) list[i] = expense;
    return expense;
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async =>
      _expenses[groupId]?.removeWhere((e) => e.expenseId == expenseId);

  @override
  Future<void> addExpensesBatch(String groupId, List<Expense> expenses) async {
    for (final e in expenses) { await addExpense(groupId, e); }
  }

  @override
  Future<int> deleteAllExpenses(String groupId) async {
    final count = _expenses[groupId]?.length ?? 0;
    _expenses[groupId]?.clear();
    return count;
  }

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) =>
      Stream.value(List.unmodifiable(_settlements[groupId] ?? []));

  @override
  Future<Settlement> addSettlement(String groupId, Settlement settlement) async {
    _settlements.putIfAbsent(groupId, () => []).add(settlement);
    return settlement;
  }

  @override
  Future<void> sendNotificationToUser(String recipientUid, Map<String, dynamic> payload) async {}
  @override
  Stream<List<Map<String, dynamic>>> watchPendingNotifications(String uid) => Stream.value([]);
  @override
  Future<void> deleteNotification(String uid, String notificationId) async {}
}

// ── Fixtures ──────────────────────────────────────────────────────────────────
Group _group() {
  final alice = Member(memberId: 'alice', name: 'Alice', email: 'a@e.com', joinedAt: DateTime(2024), role: MemberRole.owner);
  final bob = Member(memberId: 'bob', name: 'Bob', email: 'b@e.com', joinedAt: DateTime(2024));
  return Group(groupId: 'g1', name: 'Viaje', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024), members: [alice, bob], memberIds: ['alice', 'bob']);
}

Expense _expense({String id = 'e1', double amount = 60}) => Expense(
  expenseId: id, description: 'Cena', amount: amount, currency: 'EUR',
  category: 'Comida', paidBy: 'alice',
  date: DateTime(2024, 6, 15), createdAt: DateTime(2024, 6, 15),
  splits: [
    Split(memberId: 'alice', shareAmount: amount / 2, shareType: ShareType.equal),
    Split(memberId: 'bob', shareAmount: amount / 2, shareType: ShareType.equal),
  ],
);

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  late _FakeDS ds;
  late ExpensesRepository repo;

  setUp(() {
    ds = _FakeDS()..seedGroup(_group());
    repo = ExpensesRepository(remoteDataSource: ds);
  });

  group('ExpensesRepository.exportCsv', () {
    test('genera cabecera con nombres de miembros', () {
      final csv = repo.exportCsv(_group(), [_expense()]);
      expect(csv, contains('Alice'));
      expect(csv, contains('Bob'));
    });

    test('incluye la descripción del gasto', () {
      final csv = repo.exportCsv(_group(), [_expense()]);
      expect(csv, contains('Cena'));
    });

    test('incluye la fecha en formato yyyy-MM-dd', () {
      final csv = repo.exportCsv(_group(), [_expense()]);
      expect(csv, contains('2024-06-15'));
    });

    test('incluye el importe formateado', () {
      final csv = repo.exportCsv(_group(), [_expense(amount: 100)]);
      expect(csv, contains('100.00'));
    });

    test('lista vacía genera solo cabecera', () {
      final csv = repo.exportCsv(_group(), []);
      final lines = csv.trim().split('\n');
      expect(lines.length, 1); // solo cabecera
    });

    test('múltiples gastos generan múltiples filas', () {
      final csv = repo.exportCsv(_group(), [_expense(id: 'e1'), _expense(id: 'e2', amount: 30)]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3); // cabecera + 2 filas
    });

    test('el pagador aparece en la columna PaidBy', () {
      final csv = repo.exportCsv(_group(), [_expense()]);
      expect(csv, contains('Alice')); // alice es el pagador
    });

    test('shares por miembro aparecen como columnas numéricas', () {
      final csv = repo.exportCsv(_group(), [_expense(amount: 60)]);
      expect(csv, contains('30.00')); // 60/2 = 30 por persona
    });
  });

  group('ExpensesRepository.importCsv', () {
    test('importa filas válidas y devuelve el count', () async {
      const csv = '''Date,Description,Category,Cost,Currency,Alice,Bob
2024-01-10,Pizza,Comida,30,EUR,15,-15
''';
      final count = await repo.importCsv('g1', csv);
      expect(count, 1);
    });

    test('salta filas con coste cero', () async {
      const csv = '''Date,Description,Category,Cost,Currency,Alice,Bob
2024-01-10,Gratis,Comida,0,EUR,0,0
''';
      final count = await repo.importCsv('g1', csv);
      expect(count, 0);
    });

    test('importa múltiples filas', () async {
      const csv = '''Date,Description,Category,Cost,Currency,Alice,Bob
2024-01-10,Pizza,Comida,30,EUR,15,-15
2024-01-11,Taxi,Transporte,20,EUR,10,-10
''';
      final count = await repo.importCsv('g1', csv);
      expect(count, 2);
    });

    test('soporta formato de fecha dd/MM/yyyy', () async {
      const csv = '''Date,Description,Category,Cost,Currency,Alice,Bob
10/01/2024,Pizza,Comida,30,EUR,15,-15
''';
      final count = await repo.importCsv('g1', csv);
      expect(count, 1);
    });

    test('el pagador es el miembro con valor más positivo', () async {
      const csv = '''Date,Description,Category,Cost,Currency,Alice,Bob
2024-01-10,Pizza,Comida,60,EUR,30,-30
''';
      await repo.importCsv('g1', csv);
      final expenses = ds._expenses['g1'] ?? [];
      expect(expenses.first.paidBy, 'alice');
    });
  });
}
