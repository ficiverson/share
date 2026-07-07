import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/data/balances_repository.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/models/balance.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';
import 'package:share_app/models/split.dart';

// ── In-memory datasource ──────────────────────────────────────────────────────
class _FakeDS implements FirestoreRemoteDataSourceContract {
  final Map<String, Group> _groups = {};
  final Map<String, List<Expense>> _expenses = {};
  final Map<String, List<Settlement>> _settlements = {};

  void seedGroup(Group g) => _groups[g.groupId] = g;
  void seedExpense(String groupId, Expense e) =>
      _expenses.putIfAbsent(groupId, () => []).add(e);
  void seedSettlement(String groupId, Settlement s) =>
      _settlements.putIfAbsent(groupId, () => []).add(s);

  @override Stream<List<Group>> watchGroups(String uid) => Stream.value([]);
  @override Future<List<Group>> getGroups(String uid) async => [];
  @override Stream<Group> watchGroup(String groupId) => Stream.value(_groups[groupId]!);
  @override Future<Group> createGroup(Group group) async => group;
  @override Future<Group> addMember(String groupId, Member member) async { throw UnimplementedError(); }
  @override Future<void> leaveGroup(String groupId, String uid) async {}
  @override Future<void> updateMemberName(String groupId, String uid, String name) async {}
  @override Future<void> updateGroup(String groupId, {required String name, required String currency}) async {}
  @override Future<void> deleteGroup(String groupId) async {}
  @override Stream<List<Expense>> watchExpenses(String groupId) => Stream.value([]);
  @override Future<List<Expense>> getExpenses(String groupId) async => List.unmodifiable(_expenses[groupId] ?? []);
  @override Future<Expense> addExpense(String groupId, Expense expense) async => expense;
  @override Future<Expense> updateExpense(String groupId, Expense expense) async => expense;
  @override Future<void> deleteExpense(String groupId, String expenseId) async {}
  @override Future<void> addExpensesBatch(String groupId, List<Expense> expenses) async {}
  @override Future<int> deleteAllExpenses(String groupId) async => 0;
  @override Stream<List<Settlement>> watchSettlements(String groupId) =>
      Stream.value(List.unmodifiable(_settlements[groupId] ?? []));
  @override Future<Settlement> addSettlement(String groupId, Settlement settlement) async => settlement;
  @override Future<void> sendNotificationToUser(String recipientUid, Map<String, dynamic> payload) async {}
  @override Stream<List<Map<String, dynamic>>> watchPendingNotifications(String uid) => Stream.value([]);
  @override Future<void> deleteNotification(String uid, String notificationId) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Group _group() {
  return Group(
    groupId: 'g1', name: 'Viaje', currency: 'EUR', createdBy: 'alice',
    createdAt: DateTime(2024), memberIds: ['alice', 'bob'],
    members: [
      Member(memberId: 'alice', name: 'Alice', email: 'a@e.com', joinedAt: DateTime(2024), role: MemberRole.owner),
      Member(memberId: 'bob', name: 'Bob', email: 'b@e.com', joinedAt: DateTime(2024)),
    ],
  );
}

Expense _expense({required String paidBy, required double amount, Map<String, double>? shares}) {
  final defaultShares = shares ?? {'alice': amount / 2, 'bob': amount / 2};
  return Expense(
    expenseId: 'e_${amount.toInt()}',
    description: 'Gasto',
    amount: amount,
    currency: 'EUR',
    category: '',
    paidBy: paidBy,
    date: DateTime(2024),
    createdAt: DateTime(2024),
    splits: defaultShares.entries
        .map((e) => Split(memberId: e.key, shareAmount: e.value, shareType: ShareType.equal))
        .toList(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  late _FakeDS ds;
  late BalancesRepository repo;

  setUp(() {
    ds = _FakeDS()..seedGroup(_group());
    repo = BalancesRepository(remoteDataSource: ds);
  });

  group('BalancesRepository.getBalances', () {
    test('sin gastos: balances en cero para todos los miembros', () async {
      final balances = await repo.getBalances('g1');
      expect(balances.length, 2);
      for (final b in balances) {
        expect(b.paid, 0);
        expect(b.owed, 0);
      }
    });

    test('un gasto: el pagador tiene paid > 0', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      expect(alice.paid, 60);
    });

    test('un gasto: los deudores tienen owed > 0', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      final balances = await repo.getBalances('g1');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      expect(bob.owed, 30);
    });

    test('alice net positivo: pagó más de lo que le corresponde', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      expect(alice.netAmount, closeTo(30, 0.01)); // paid 60, owed 30 → net +30
    });

    test('bob net negativo: debe dinero a alice', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      final balances = await repo.getBalances('g1');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      expect(bob.netAmount, closeTo(-30, 0.01)); // paid 0, owed 30 → net -30
    });

    test('múltiples gastos: totales acumulados', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 40));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      expect(alice.paid, 100);
    });

    test('liquidación reduce la deuda de bob', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      ds.seedSettlement('g1', Settlement(
        settlementId: 's1', fromMemberId: 'bob', toMemberId: 'alice',
        amount: 30, date: DateTime(2024), currency: 'EUR',
      ));
      final balances = await repo.getBalances('g1');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      // bob paid 30 (settlement), owed 30 → net 0
      expect(bob.netAmount, closeTo(0, 0.01));
    });

    test('gastos desiguales: shares personalizados', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 90, shares: {'alice': 30, 'bob': 60}));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      expect(alice.netAmount, closeTo(60, 0.01));  // paid 90, owed 30 → +60
      expect(bob.netAmount, closeTo(-60, 0.01));   // paid 0, owed 60 → -60
    });
  });
}
