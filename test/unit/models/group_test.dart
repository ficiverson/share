import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';

Member _member(String id, String name, {MemberRole role = MemberRole.member}) =>
    Member(memberId: id, name: name, email: '$id@e.com', joinedAt: DateTime(2024, 1, 1), role: role);

Group _group() => Group(
      groupId: 'g1',
      name: 'Viaje',
      currency: 'EUR',
      createdBy: 'alice',
      createdAt: DateTime(2024, 1, 1),
      memberIds: ['alice', 'bob'],
      members: [
        _member('alice', 'Alice', role: MemberRole.owner),
        _member('bob', 'Bob'),
      ],
    );

void main() {
  group('Group', () {
    test('constructor asigna todos los campos', () {
      final g = _group();
      expect(g.groupId, 'g1');
      expect(g.name, 'Viaje');
      expect(g.currency, 'EUR');
      expect(g.createdBy, 'alice');
      expect(g.memberIds, ['alice', 'bob']);
      expect(g.members.length, 2);
    });

    test('memberIds y members por defecto vacíos', () {
      final g = Group(
        groupId: 'g2', name: 'Test', currency: 'USD',
        createdBy: 'uid', createdAt: DateTime(2024),
      );
      expect(g.memberIds, isEmpty);
      expect(g.members, isEmpty);
    });

    test('toMap serializa members como mapa anidado por uid', () {
      final map = _group().toMap();
      expect(map['name'], 'Viaje');
      expect(map['currency'], 'EUR');
      expect(map['createdBy'], 'alice');
      final membersMap = map['members'] as Map;
      expect(membersMap.keys, containsAll(['alice', 'bob']));
      expect((membersMap['alice'] as Map)['name'], 'Alice');
    });

    test('fromMap deserializa correctamente', () {
      final g = _group();
      final map = g.toMap();
      final restored = Group.fromMap('g1', map);
      expect(restored.groupId, 'g1');
      expect(restored.name, 'Viaje');
      expect(restored.currency, 'EUR');
      expect(restored.createdBy, 'alice');
      expect(restored.members.length, 2);
    });

    test('fromMap con mapa vacío usa defaults', () {
      final g = Group.fromMap('gx', {});
      expect(g.name, '');
      expect(g.currency, 'EUR');
      expect(g.createdBy, '');
      expect(g.memberIds, isEmpty);
      expect(g.members, isEmpty);
    });

    test('copyWith cambia members y memberIds', () {
      final g = _group();
      final charlie = _member('charlie', 'Charlie');
      final updated = g.copyWith(
        members: [...g.members, charlie],
        memberIds: [...g.memberIds, 'charlie'],
      );
      expect(updated.members.length, 3);
      expect(updated.memberIds.length, 3);
      expect(updated.name, g.name); // unchanged
    });

    test('fromMap con members como mapa vacío produce lista vacía', () {
      final g = Group.fromMap('g1', {'name': 'X', 'members': {}});
      expect(g.members, isEmpty);
    });

    test('round-trip conserva role de miembros', () {
      final g = _group();
      final restored = Group.fromMap('g1', g.toMap());
      final alice = restored.members.firstWhere((m) => m.memberId == 'alice');
      expect(alice.role, MemberRole.owner);
    });
  });
}
