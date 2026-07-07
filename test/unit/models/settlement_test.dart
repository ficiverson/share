import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/models/settlement.dart';

Settlement _make({
  String id = 's1',
  String from = 'bob',
  String to = 'alice',
  double amount = 30.0,
  String notes = '',
}) =>
    Settlement(
      settlementId: id,
      fromMemberId: from,
      toMemberId: to,
      amount: amount,
      date: DateTime(2024, 6, 16),
      notes: notes,
    );

void main() {
  group('Settlement', () {
    test('constructor asigna todos los campos', () {
      final s = _make(notes: 'Pago de deuda');
      expect(s.settlementId, 's1');
      expect(s.fromMemberId, 'bob');
      expect(s.toMemberId, 'alice');
      expect(s.amount, 30.0);
      expect(s.notes, 'Pago de deuda');
    });

    test('notes por defecto vacío', () {
      expect(_make().notes, '');
    });

    test('toMap serializa correctamente', () {
      final map = _make().toMap();
      expect(map['fromMemberId'], 'bob');
      expect(map['toMemberId'], 'alice');
      expect(map['amount'], 30.0);
      expect(map['notes'], '');
      expect(map['date'], isA<String>());
    });

    test('fromMap deserializa correctamente', () {
      final s = _make();
      final restored = Settlement.fromMap('s1', s.toMap());
      expect(restored.settlementId, 's1');
      expect(restored.fromMemberId, 'bob');
      expect(restored.toMemberId, 'alice');
      expect(restored.amount, 30.0);
      expect(restored.date.year, 2024);
    });

    test('fromMap con mapa vacío usa defaults', () {
      final s = Settlement.fromMap('sid', {});
      expect(s.fromMemberId, '');
      expect(s.toMemberId, '');
      expect(s.amount, 0.0);
      expect(s.notes, '');
    });

    test('round-trip toMap/fromMap conserva todos los campos', () {
      final original = _make(notes: 'mitad de alquiler');
      final restored = Settlement.fromMap('s1', original.toMap());
      expect(restored.fromMemberId, original.fromMemberId);
      expect(restored.toMemberId, original.toMemberId);
      expect(restored.amount, original.amount);
      expect(restored.notes, original.notes);
    });

    test('Settlement con currency en mapa (campo nuevo) no rompe', () {
      final s = Settlement.fromMap('s1', {
        'fromMemberId': 'a',
        'toMemberId': 'b',
        'amount': 50.0,
        'date': '2024-01-01T00:00:00.000',
        'currency': 'EUR',
      });
      expect(s.amount, 50.0);
    });
  });
}
