import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/models/balance.dart';

void main() {
  group('MemberBalance', () {
    test('netAmount = paid - owed', () {
      final b = MemberBalance(memberId: 'alice', paid: 90, owed: 30);
      expect(b.netAmount, 60);
    });

    test('netAmount negativo cuando owed > paid', () {
      final b = MemberBalance(memberId: 'bob', paid: 0, owed: 45);
      expect(b.netAmount, -45);
    });

    test('netAmount cero cuando paid == owed', () {
      final b = MemberBalance(memberId: 'charlie', paid: 30, owed: 30);
      expect(b.netAmount, 0);
    });
  });

  group('DebtTransfer', () {
    test('constructor asigna todos los campos', () {
      final t = DebtTransfer(fromMemberId: 'bob', toMemberId: 'alice', amount: 30);
      expect(t.fromMemberId, 'bob');
      expect(t.toMemberId, 'alice');
      expect(t.amount, 30);
    });
  });
}
