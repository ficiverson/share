import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/split.dart';

Expense _make({
  String id = 'e1',
  String description = 'Cena',
  double amount = 90.0,
  String paidBy = 'alice',
  String createdBy = 'alice',
  String currency = 'EUR',
  String category = 'Comida',
  String notes = 'Nota',
  List<Split>? splits,
}) =>
    Expense(
      expenseId: id,
      description: description,
      amount: amount,
      currency: currency,
      category: category,
      paidBy: paidBy,
      createdBy: createdBy,
      date: DateTime(2024, 6, 15),
      createdAt: DateTime(2024, 6, 15, 20, 0),
      notes: notes,
      splits: splits ??
          [
            Split(memberId: 'alice', shareAmount: 45.0, shareType: ShareType.equal),
            Split(memberId: 'bob', shareAmount: 45.0, shareType: ShareType.equal),
          ],
    );

void main() {
  group('Expense', () {
    test('constructor asigna todos los campos', () {
      final e = _make();
      expect(e.expenseId, 'e1');
      expect(e.description, 'Cena');
      expect(e.amount, 90.0);
      expect(e.currency, 'EUR');
      expect(e.category, 'Comida');
      expect(e.paidBy, 'alice');
      expect(e.createdBy, 'alice');
      expect(e.notes, 'Nota');
      expect(e.splits.length, 2);
    });

    test('createdBy defaults a vacío si no se pasa', () {
      final e = Expense(
        expenseId: 'e2',
        description: 'X',
        amount: 10,
        currency: 'EUR',
        category: '',
        paidBy: 'uid',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(e.createdBy, '');
      expect(e.notes, '');
      expect(e.splits, isEmpty);
    });

    test('toMap serializa todos los campos', () {
      final e = _make();
      final map = e.toMap();
      expect(map['description'], 'Cena');
      expect(map['amount'], 90.0);
      expect(map['currency'], 'EUR');
      expect(map['category'], 'Comida');
      expect(map['paidBy'], 'alice');
      expect(map['createdBy'], 'alice');
      expect(map['notes'], 'Nota');
      expect((map['splits'] as List).length, 2);
    });

    test('fromMap deserializa todos los campos', () {
      final e = _make();
      final map = e.toMap();
      final restored = Expense.fromMap('e1', map);
      expect(restored.expenseId, 'e1');
      expect(restored.description, 'Cena');
      expect(restored.amount, 90.0);
      expect(restored.currency, 'EUR');
      expect(restored.notes, 'Nota');
      expect(restored.splits.length, 2);
    });

    test('fromMap con mapa vacío usa defaults seguros', () {
      final e = Expense.fromMap('eid', {});
      expect(e.description, '');
      expect(e.amount, 0.0);
      expect(e.currency, 'EUR');
      expect(e.paidBy, '');
      expect(e.createdBy, '');
      expect(e.notes, '');
      expect(e.splits, isEmpty);
    });

    test('round-trip toMap/fromMap conserva splits exactos', () {
      final e = _make(splits: [
        Split(memberId: 'alice', shareAmount: 500, shareType: ShareType.exact),
        Split(memberId: 'bob', shareAmount: 400, shareType: ShareType.exact),
      ], amount: 900);
      final restored = Expense.fromMap('e1', e.toMap());
      expect(restored.splits.first.shareType, ShareType.exact);
      expect(restored.splits.first.shareAmount, 500);
    });

    test('round-trip fecha preserva año/mes/día', () {
      final e = _make();
      final restored = Expense.fromMap('e1', e.toMap());
      expect(restored.date.year, 2024);
      expect(restored.date.month, 6);
      expect(restored.date.day, 15);
    });

    // ── payments (pago compartido) ─────────────────────────────────────────
    test('payments defaults a lista vacía', () {
      final e = _make();
      expect(e.payments, isEmpty);
    });

    test('constructor acepta payments no vacíos', () {
      expect(_make().payments, isEmpty); // compile-check del getter
      final e2 = Expense(
        expenseId: 'e1',
        description: 'Cena',
        amount: 90,
        currency: 'EUR',
        category: '',
        paidBy: 'alice',
        date: DateTime(2024),
        createdAt: DateTime(2024),
        payments: [
          Split(memberId: 'alice', shareAmount: 50, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 40, shareType: ShareType.exact),
        ],
      );
      expect(e2.payments.length, 2);
      expect(e2.payments.first.memberId, 'alice');
      expect(e2.payments.first.shareAmount, 50);
    });

    test('toMap serializa payments', () {
      final e = Expense(
        expenseId: 'e1',
        description: 'Test',
        amount: 90,
        currency: 'EUR',
        category: '',
        paidBy: 'alice',
        date: DateTime(2024),
        createdAt: DateTime(2024),
        payments: [
          Split(memberId: 'alice', shareAmount: 50, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 40, shareType: ShareType.exact),
        ],
      );
      final map = e.toMap();
      final payments = map['payments'] as List;
      expect(payments.length, 2);
      expect(payments.first['memberId'], 'alice');
      expect(payments.first['shareAmount'], 50.0);
    });

    test('fromMap deserializa payments', () {
      final map = {
        'description': 'Test',
        'amount': 90.0,
        'currency': 'EUR',
        'category': '',
        'paidBy': 'alice',
        'createdBy': '',
        'date': '2024-01-01T00:00:00.000',
        'createdAt': '2024-01-01T00:00:00.000',
        'notes': '',
        'splits': [],
        'payments': [
          {'memberId': 'alice', 'shareAmount': 50.0, 'shareType': 'exact'},
          {'memberId': 'bob', 'shareAmount': 40.0, 'shareType': 'exact'},
        ],
      };
      final e = Expense.fromMap('e1', map);
      expect(e.payments.length, 2);
      expect(e.payments.first.memberId, 'alice');
      expect(e.payments[1].shareAmount, 40.0);
    });

    test('fromMap sin campo payments usa lista vacía (backward compat)', () {
      final map = {
        'description': 'Legacy',
        'amount': 30.0,
        'currency': 'EUR',
        'category': '',
        'paidBy': 'alice',
        'createdBy': '',
        'date': '2024-01-01T00:00:00.000',
        'createdAt': '2024-01-01T00:00:00.000',
        'notes': '',
        'splits': [],
        // sin campo 'payments' → backward compat
      };
      final e = Expense.fromMap('e1', map);
      expect(e.payments, isEmpty);
    });

    test('round-trip toMap/fromMap conserva payments', () {
      final original = Expense(
        expenseId: 'e1',
        description: 'Compartido',
        amount: 90,
        currency: 'EUR',
        category: '',
        paidBy: 'alice',
        date: DateTime(2024),
        createdAt: DateTime(2024),
        payments: [
          Split(memberId: 'alice', shareAmount: 50, shareType: ShareType.exact),
          Split(memberId: 'bob', shareAmount: 40, shareType: ShareType.exact),
        ],
      );
      final restored = Expense.fromMap('e1', original.toMap());
      expect(restored.payments.length, 2);
      expect(restored.payments.first.shareAmount, 50);
      expect(restored.payments[1].memberId, 'bob');
    });
  });
}
