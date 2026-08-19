import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/usecase/add_expense_use_case.dart';
import 'package:share_app/domain/usecase/edit_expense_use_case.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';
import 'package:share_app/models/split.dart';
import 'package:share_app/ui/expenses/expense_form_presenter.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeView implements ExpenseFormViewContract {
  bool saving = false;
  Expense? saved;
  String? error;

  @override void onSaving(bool v) => saving = v;
  @override void onSaved(Expense e) => saved = e;
  @override void onSaveError(String e) => error = e;
}

class _FakeDS implements FirestoreRemoteDataSourceContract {
  /// Notificaciones enviadas: recipient → lista de payloads.
  final Map<String, List<Map<String, dynamic>>> sent = {};

  @override
  Future<void> sendNotificationToUser(
      String recipientUid, Map<String, dynamic> payload) async {
    sent.putIfAbsent(recipientUid, () => []).add(payload);
  }

  // Stubs mínimos — no usados en estos tests.
  @override Stream<List<Group>> watchGroups(String uid) => Stream.value([]);
  @override Future<List<Group>> getGroups(String uid) async => [];
  @override Stream<Group> watchGroup(String groupId) => const Stream.empty();
  @override Future<Group> createGroup(Group g) async => g;
  @override Future<Group> addMember(String gid, Member m) async => throw UnimplementedError();
  @override Future<void> leaveGroup(String gid, String uid) async {}
  @override Future<void> updateMemberName(String gid, String uid, String n) async {}
  @override Future<void> updateGroup(String gid, {required String name, required String currency}) async {}
  @override Future<void> deleteGroup(String gid) async {}
  @override Stream<List<Expense>> watchExpenses(String gid) => Stream.value([]);
  @override Future<List<Expense>> getExpenses(String gid) async => [];
  @override Future<Expense> addExpense(String gid, Expense e) async => e;
  @override Future<Expense> updateExpense(String gid, Expense e) async => e;
  @override Future<void> deleteExpense(String gid, String eid) async {}
  @override Future<void> addExpensesBatch(String gid, List<Expense> es) async {}
  @override Future<int> deleteAllExpenses(String gid) async => 0;
  @override Stream<List<Settlement>> watchSettlements(String gid) => Stream.value([]);
  @override Future<Settlement> addSettlement(String gid, Settlement s) async => s;
  @override Stream<List<Map<String, dynamic>>> watchPendingNotifications(String uid) => Stream.value([]);
  @override Future<void> deleteNotification(String uid, String nid) async {}
}

// AddExpenseUseCase que devuelve el gasto tal cual (sin Firestore real).
class _FakeAddUseCase extends AddExpenseUseCase {
  _FakeAddUseCase() : super(repository: _NullExpensesRepo());

  @override
  void invoke() {
    final p = params!;
    notifyListeners(Future.value(Success(
      Expense(
        expenseId: 'eid1',
        description: p.expense.description,
        amount: p.expense.amount,
        currency: p.expense.currency,
        category: p.expense.category,
        paidBy: p.expense.paidBy,
        createdBy: p.expense.createdBy,
        date: p.expense.date,
        createdAt: p.expense.createdAt,
        splits: p.expense.splits,
        payments: p.expense.payments,
      ),
      Status.ok,
    )));
  }
}

class _NullExpensesRepo implements ExpensesRepositoryContract {
  @override dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

Group _group() => Group(
      groupId: 'g1',
      name: 'Viaje',
      currency: 'EUR',
      createdBy: 'alice',
      createdAt: DateTime(2024),
      memberIds: ['alice', 'bob', 'charlie'],
      members: [
        Member(memberId: 'alice', name: 'Alice', email: 'a@e.com', joinedAt: DateTime(2024), role: MemberRole.owner),
        Member(memberId: 'bob', name: 'Bob', email: 'b@e.com', joinedAt: DateTime(2024)),
        Member(memberId: 'charlie', name: 'Charlie', email: 'c@e.com', joinedAt: DateTime(2024)),
      ],
    );

Expense _expense({
  String createdBy = 'alice',
  String paidBy = 'alice',
  double amount = 60,
  List<Split> splits = const [],
  List<Split> payments = const [],
}) =>
    Expense(
      expenseId: '',
      description: 'Cena',
      amount: amount,
      currency: 'EUR',
      category: 'Comida',
      paidBy: paidBy,
      createdBy: createdBy,
      date: DateTime(2024),
      createdAt: DateTime(2024),
      splits: splits.isEmpty
          ? [
              Split(memberId: 'alice', shareAmount: amount / 3, shareType: ShareType.equal),
              Split(memberId: 'bob', shareAmount: amount / 3, shareType: ShareType.equal),
              Split(memberId: 'charlie', shareAmount: amount / 3, shareType: ShareType.equal),
            ]
          : splits,
      payments: payments,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeView view;
  late _FakeDS ds;
  late ExpenseFormPresenter presenter;

  setUp(() {
    view = _FakeView();
    ds = _FakeDS();
    presenter = ExpenseFormPresenter(
      view,
      invoker: Invoker(),
      addExpenseUseCase: _FakeAddUseCase(),
      editExpenseUseCase: EditExpenseUseCase(repository: _NullExpensesRepo()),
      firestoreDataSource: ds,
    );
  });

  group('ExpenseFormPresenter._sendNotifications — pagador único', () {
    test('no envía notificación al creador del gasto', () async {
      // alice crea y paga; solo bob y charlie deben recibir notificación
      presenter.save('g1', _expense(createdBy: 'alice', paidBy: 'alice'), _group());
      await Future.delayed(Duration.zero);

      expect(ds.sent.containsKey('alice'), isFalse);
      expect(ds.sent.containsKey('bob'), isTrue);
      expect(ds.sent.containsKey('charlie'), isTrue);
    });

    test('body incluye nombre del pagador y la parte del destinatario', () async {
      presenter.save('g1', _expense(createdBy: 'alice', paidBy: 'alice', amount: 60), _group());
      await Future.delayed(Duration.zero);

      final bobBody = ds.sent['bob']!.first['body'] as String;
      expect(bobBody, contains('Alice'));       // nombre del pagador
      expect(bobBody, contains('20'));          // 60/3 = 20 € parte de bob
      expect(bobBody, contains('te toca'));
    });

    test('body es diferente para cada miembro según su split', () async {
      // Reparto desigual: bob debe 10, charlie debe 40
      final expense = _expense(
        createdBy: 'alice',
        paidBy: 'alice',
        amount: 60,
        splits: [
          Split(memberId: 'alice', shareAmount: 10, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 10, shareType: ShareType.exact),
          Split(memberId: 'charlie', shareAmount: 40, shareType: ShareType.exact),
        ],
      );
      presenter.save('g1', expense, _group());
      await Future.delayed(Duration.zero);

      final bobBody = ds.sent['bob']!.first['body'] as String;
      final charlieBody = ds.sent['charlie']!.first['body'] as String;
      expect(bobBody, contains('10'));
      expect(charlieBody, contains('40'));
      expect(bobBody == charlieBody, isFalse);
    });

    test('miembro sin split recibe body con importe total (no "te toca")', () async {
      // charlie no aparece en splits
      final expense = _expense(
        createdBy: 'alice',
        paidBy: 'alice',
        amount: 60,
        splits: [
          Split(memberId: 'alice', shareAmount: 30, shareType: ShareType.equal),
          Split(memberId: 'bob', shareAmount: 30, shareType: ShareType.equal),
        ],
      );
      presenter.save('g1', expense, _group());
      await Future.delayed(Duration.zero);

      final charlieBody = ds.sent['charlie']!.first['body'] as String;
      expect(charlieBody, isNot(contains('te toca')));
      expect(charlieBody, contains('60'));
    });
  });

  group('ExpenseFormPresenter._sendNotifications — pagadores múltiples', () {
    test('body incluye todos los nombres de pagadores', () async {
      // alice y bob pagan; charlie recibe la notificación
      final expense = _expense(
        createdBy: 'charlie',
        paidBy: 'alice',
        amount: 60,
        payments: [
          Split(memberId: 'alice', shareAmount: 40, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 20, shareType: ShareType.exact),
        ],
      );
      presenter.save('g1', expense, _group());
      await Future.delayed(Duration.zero);

      final aliceBody = ds.sent['alice']!.first['body'] as String;
      expect(aliceBody, contains('Alice'));
      expect(aliceBody, contains('Bob'));
    });

    test('body muestra la parte correcta del destinatario con multi-payer', () async {
      // alice paga 10, bob paga 5.23; total 15.23, split igualitario ~5.077 cada uno
      final expense = _expense(
        createdBy: 'charlie',
        paidBy: 'alice',
        amount: 15.23,
        splits: [
          Split(memberId: 'alice', shareAmount: 5.077, shareType: ShareType.equal),
          Split(memberId: 'bob', shareAmount: 5.077, shareType: ShareType.equal),
          Split(memberId: 'charlie', shareAmount: 5.076, shareType: ShareType.equal),
        ],
        payments: [
          Split(memberId: 'alice', shareAmount: 10.0, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 5.23, shareType: ShareType.exact),
        ],
      );
      presenter.save('g1', expense, _group());
      await Future.delayed(Duration.zero);

      // charlie recibe notificación con su parte (~5.076)
      final charlieBody = ds.sent['charlie']!.first['body'] as String;
      expect(charlieBody, contains('te toca'));
      expect(charlieBody, contains('5'));
    });
  });
}
