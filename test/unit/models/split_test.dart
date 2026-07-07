import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/models/split.dart';

void main() {
  group('Split', () {
    test('constructor asigna todos los campos', () {
      final s = Split(memberId: 'uid', shareAmount: 25.0, shareType: ShareType.exact);
      expect(s.memberId, 'uid');
      expect(s.shareAmount, 25.0);
      expect(s.shareType, ShareType.exact);
    });

    test('shareType por defecto es equal', () {
      final s = Split(memberId: 'uid', shareAmount: 10.0);
      expect(s.shareType, ShareType.equal);
    });

    test('toMap serializa correctamente', () {
      final s = Split(memberId: 'uid', shareAmount: 33.33, shareType: ShareType.percentage);
      final map = s.toMap();
      expect(map['memberId'], 'uid');
      expect(map['shareAmount'], 33.33);
      expect(map['shareType'], 'percentage');
    });

    test('fromMap deserializa correctamente', () {
      final map = {'memberId': 'bob', 'shareAmount': 50.0, 'shareType': 'exact'};
      final s = Split.fromMap(map);
      expect(s.memberId, 'bob');
      expect(s.shareAmount, 50.0);
      expect(s.shareType, ShareType.exact);
    });

    test('fromMap con shareType desconocido usa equal', () {
      final s = Split.fromMap({'memberId': 'x', 'shareAmount': 10.0, 'shareType': 'unknown'});
      expect(s.shareType, ShareType.equal);
    });

    test('fromMap con campos ausentes usa defaults', () {
      final s = Split.fromMap({});
      expect(s.memberId, '');
      expect(s.shareAmount, 0.0);
      expect(s.shareType, ShareType.equal);
    });

    test('round-trip toMap/fromMap conserva valores', () {
      final original = Split(memberId: 'alice', shareAmount: 42.5, shareType: ShareType.exact);
      final restored = Split.fromMap(original.toMap());
      expect(restored.memberId, original.memberId);
      expect(restored.shareAmount, original.shareAmount);
      expect(restored.shareType, original.shareType);
    });

    test('ShareType.values contiene los tres tipos', () {
      expect(ShareType.values, containsAll([ShareType.equal, ShareType.exact, ShareType.percentage]));
    });
  });
}
