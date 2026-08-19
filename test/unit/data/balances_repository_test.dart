import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/data/balances_repository.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
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

Expense _expense({
  required String paidBy,
  required double amount,
  Map<String, double>? shares,
  List<Split>? payments,
}) {
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
    payments: payments ?? [],
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

  // ── getUserBalance ────────────────────────────────────────────────────────────
  group('BalancesRepository.getUserBalance', () {
    test('single-payer: net correcto para el pagador', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      final balance = await repo.getUserBalance('g1', 'alice');
      expect(balance.memberId, 'alice');
      expect(balance.paid, closeTo(60, 0.01));
      expect(balance.owed, closeTo(30, 0.01));
      expect(balance.netAmount, closeTo(30, 0.01));
    });

    test('single-payer: net correcto para el deudor', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      final balance = await repo.getUserBalance('g1', 'bob');
      expect(balance.paid, closeTo(0, 0.01));
      expect(balance.owed, closeTo(30, 0.01));
      expect(balance.netAmount, closeTo(-30, 0.01));
    });

    test('multi-payer: usa payments en lugar de paidBy', () async {
      ds.seedExpense('g1', _expense(
        paidBy: 'alice',
        amount: 15.23,
        payments: [
          Split(memberId: 'alice', shareAmount: 10.0, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 5.23, shareType: ShareType.exact),
        ],
      ));
      final alice = await repo.getUserBalance('g1', 'alice');
      final bob = await repo.getUserBalance('g1', 'bob');
      expect(alice.netAmount, closeTo(10.0 - 15.23 / 2, 0.01)); // +2.385
      expect(bob.netAmount, closeTo(5.23 - 15.23 / 2, 0.01));   // -2.385
    });

    test('liquidación ajusta el balance del usuario', () async {
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      ds.seedSettlement('g1', Settlement(
        settlementId: 's1', fromMemberId: 'bob', toMemberId: 'alice',
        amount: 30, date: DateTime(2024), currency: 'EUR',
      ));
      final bob = await repo.getUserBalance('g1', 'bob');
      expect(bob.netAmount, closeTo(0, 0.01));
    });

    test('sin gastos: balance en cero', () async {
      final balance = await repo.getUserBalance('g1', 'alice');
      expect(balance.paid, 0);
      expect(balance.owed, 0);
    });

    test('múltiples gastos: paid y owed se acumulan correctamente', () async {
      // Gasto 1: alice paga 60, split 30/30
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      // Gasto 2: bob paga 40, split 20/20
      ds.seedExpense('g1', _expense(paidBy: 'bob', amount: 40));
      final alice = await repo.getUserBalance('g1', 'alice');
      // alice: paid=60, owed=30+20=50, net=+10
      expect(alice.paid, closeTo(60, 0.01));
      expect(alice.owed, closeTo(50, 0.01));
      expect(alice.netAmount, closeTo(10, 0.01));
    });

    test('liquidación como receptor: owed sube para cancelar crédito', () async {
      // alice pagó 60, bob le debe 30. Bob liquida → alice recibe el pago.
      // Tras la liquidación alice.net debe ser 0.
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      ds.seedSettlement('g1', Settlement(
        settlementId: 's1', fromMemberId: 'bob', toMemberId: 'alice',
        amount: 30, date: DateTime(2024), currency: 'EUR',
      ));
      final alice = await repo.getUserBalance('g1', 'alice');
      // paid=60, owed=30(split)+30(settlement recibido)=60, net=0
      expect(alice.netAmount, closeTo(0, 0.01));
    });

    test('uid no participa en ningún split ni payment: balance en cero', () async {
      // Gasto solo entre alice y bob; alice no está en grupo g1 aquí
      // pero el método devuelve 0 si no hay actividad relacionada
      ds.seedExpense('g1', Expense(
        expenseId: 'e1', description: 'Algo', amount: 40,
        currency: 'EUR', category: '', paidBy: 'bob',
        date: DateTime(2024), createdAt: DateTime(2024),
        splits: [Split(memberId: 'bob', shareAmount: 40, shareType: ShareType.equal)],
        payments: [],
      ));
      final alice = await repo.getUserBalance('g1', 'alice');
      expect(alice.paid, 0);
      expect(alice.owed, 0);
      expect(alice.netAmount, 0);
    });
  });

  // ── Pago compartido (payments) ────────────────────────────────────────────────
  group('BalancesRepository.getBalances — pago compartido', () {
    test('con payments: ignora paidBy y usa los pagos individuales', () async {
      ds.seedExpense('g1', _expense(
        paidBy: 'alice', // se ignorará porque hay payments
        amount: 60,
        payments: [
          Split(memberId: 'alice', shareAmount: 30, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 30, shareType: ShareType.exact),
        ],
      ));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      expect(alice.paid, closeTo(30, 0.01));
      expect(bob.paid, closeTo(30, 0.01));
    });

    test('pago compartido igual: net de ambos es 0 si splits iguales', () async {
      ds.seedExpense('g1', _expense(
        paidBy: 'alice',
        amount: 60,
        payments: [
          Split(memberId: 'alice', shareAmount: 30, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 30, shareType: ShareType.exact),
        ],
      ));
      final balances = await repo.getBalances('g1');
      for (final b in balances) {
        // paid 30, owed 30 → net 0 para ambos
        expect(b.netAmount, closeTo(0, 0.01));
      }
    });

    test('pago compartido desigual: alice pagó más, bob debe diferencia', () async {
      // Alice pagó 50, Bob pagó 10. Gasto repartido 50/50 (30 cada uno).
      // → alice: paid=50, owed=30, net=+20
      // → bob:   paid=10, owed=30, net=-20
      ds.seedExpense('g1', _expense(
        paidBy: 'alice',
        amount: 60,
        payments: [
          Split(memberId: 'alice', shareAmount: 50, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 10, shareType: ShareType.exact),
        ],
      ));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      expect(alice.netAmount, closeTo(20, 0.01));
      expect(bob.netAmount, closeTo(-20, 0.01));
    });

    test('mezcla de gasto único y gasto compartido', () async {
      // Gasto 1: alice paga 60 sola → alice paid+60
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60));
      // Gasto 2: alice y bob pagan 40 a medias → alice paid+20, bob paid+20
      ds.seedExpense('g1', _expense(
        paidBy: 'alice',
        amount: 40,
        payments: [
          Split(memberId: 'alice', shareAmount: 20, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 20, shareType: ShareType.exact),
        ],
      ));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      // alice paid = 60 + 20 = 80, owed = 50, net = +30
      // bob paid = 20, owed = 50, net = -30
      expect(alice.paid, closeTo(80, 0.01));
      expect(bob.paid, closeTo(20, 0.01));
      expect(alice.netAmount, closeTo(30, 0.01));
      expect(bob.netAmount, closeTo(-30, 0.01));
    });

    test('payments vacíos: fallback correcto a paidBy', () async {
      // payments vacío → sigue usando paidBy como antes
      ds.seedExpense('g1', _expense(paidBy: 'alice', amount: 60, payments: []));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      expect(alice.paid, closeTo(60, 0.01));
    });

    // ── Escenario exacto del bug reportado ───────────────────────────────────
    // Fer pagó 10 €, Gemma pagó 5,23 €. Total: 15,23 €. Reparto igualitario.
    // BUG: si payments se pierde al guardar, el sistema usa paidBy=fer con
    //      amount=15,23 → net fer = +7,615 (INCORRECTO).
    // CORRECTO: net fer = 10 - 7,615 = +2,385; net gemma = 5,23 - 7,615 = -2,385.
    test('bug: pago desigual con importe decimal — net correcto, no la mitad del total', () async {
      const total = 15.23;
      const ferPago = 10.0;
      const gemmaPago = 5.23;
      const share = total / 2; // 7.615

      ds.seedExpense('g1', _expense(
        paidBy: 'alice', // alice = "fer" en el bug original
        amount: total,
        payments: [
          Split(memberId: 'alice', shareAmount: ferPago, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: gemmaPago, shareType: ShareType.exact),
        ],
      ));
      final balances = await repo.getBalances('g1');
      final fer = balances.firstWhere((b) => b.memberId == 'alice');
      final gemma = balances.firstWhere((b) => b.memberId == 'bob');

      // Si payments se pierde, fer.netAmount sería +7,615 (INCORRECTO)
      expect(fer.netAmount, isNot(closeTo(share, 0.01)),
          reason: 'payments perdidos daría net = mitad del total (bug)');

      // Valor correcto
      expect(fer.netAmount, closeTo(ferPago - share, 0.01));   // +2.385
      expect(gemma.netAmount, closeTo(gemmaPago - share, 0.01)); // -2.385
    });

    test('pago desigual + reparto desigual: netos independientes', () async {
      // alice paga 10, bob paga 5.23. Reparto: alice debe 3, bob debe 12.23.
      // net alice: 10 - 3 = +7     net bob: 5.23 - 12.23 = -7
      ds.seedExpense('g1', _expense(
        paidBy: 'alice',
        amount: 15.23,
        shares: {'alice': 3.0, 'bob': 12.23},
        payments: [
          Split(memberId: 'alice', shareAmount: 10.0, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 5.23, shareType: ShareType.exact),
        ],
      ));
      final balances = await repo.getBalances('g1');
      final alice = balances.firstWhere((b) => b.memberId == 'alice');
      final bob = balances.firstWhere((b) => b.memberId == 'bob');
      expect(alice.netAmount, closeTo(7.0, 0.01));
      expect(bob.netAmount, closeTo(-7.0, 0.01));
    });

    test('tres pagadores: cada uno acumula su parte', () async {
      // Añadimos charlie al grupo
      ds.seedGroup(Group(
        groupId: 'g1', name: 'Viaje', currency: 'EUR', createdBy: 'alice',
        createdAt: DateTime(2024), memberIds: ['alice', 'bob', 'charlie'],
        members: [
          Member(memberId: 'alice', name: 'Alice', email: 'a@e.com', joinedAt: DateTime(2024), role: MemberRole.owner),
          Member(memberId: 'bob', name: 'Bob', email: 'b@e.com', joinedAt: DateTime(2024)),
          Member(memberId: 'charlie', name: 'Charlie', email: 'c@e.com', joinedAt: DateTime(2024)),
        ],
      ));
      ds.seedExpense('g1', Expense(
        expenseId: 'e1',
        description: 'Cena',
        amount: 90,
        currency: 'EUR',
        category: '',
        paidBy: 'alice',
        date: DateTime(2024),
        createdAt: DateTime(2024),
        splits: [
          Split(memberId: 'alice', shareAmount: 30, shareType: ShareType.equal),
          Split(memberId: 'bob', shareAmount: 30, shareType: ShareType.equal),
          Split(memberId: 'charlie', shareAmount: 30, shareType: ShareType.equal),
        ],
        payments: [
          Split(memberId: 'alice', shareAmount: 30, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 30, shareType: ShareType.exact),
          Split(memberId: 'charlie', shareAmount: 30, shareType: ShareType.exact),
        ],
      ));
      final balances = await repo.getBalances('g1');
      for (final b in balances) {
        // Cada uno pagó 30 y debe 30 → net = 0
        expect(b.netAmount, closeTo(0, 0.01),
            reason: '${b.memberId} debería tener net 0');
      }
    });
  });
}
