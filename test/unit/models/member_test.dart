import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/models/member.dart';

Member _make({
  String id = 'uid1',
  String name = 'Alice',
  String email = 'alice@example.com',
  MemberRole role = MemberRole.member,
}) =>
    Member(memberId: id, name: name, email: email, joinedAt: DateTime(2024, 1, 1), role: role);

void main() {
  group('Member', () {
    test('constructor asigna todos los campos', () {
      final m = _make(role: MemberRole.owner);
      expect(m.memberId, 'uid1');
      expect(m.name, 'Alice');
      expect(m.email, 'alice@example.com');
      expect(m.role, MemberRole.owner);
    });

    test('role por defecto es member', () {
      final m = Member(memberId: 'x', name: 'X', email: 'x@x.com', joinedAt: DateTime(2024));
      expect(m.role, MemberRole.member);
    });

    test('displayName alias devuelve name', () {
      expect(_make(name: 'Bob').displayName, 'Bob');
    });

    test('id alias devuelve memberId', () {
      expect(_make(id: 'uid_42').id, 'uid_42');
    });

    test('toMap incluye el campo role', () {
      final map = _make(role: MemberRole.owner).toMap();
      expect(map['role'], 'owner');
      expect(map['name'], 'Alice');
      expect(map['email'], 'alice@example.com');
    });

    test('fromMap deserializa role owner', () {
      final m = Member.fromMap('uid1', {
        'name': 'Alice',
        'email': 'a@e.com',
        'joinedAt': '2024-01-01T00:00:00.000',
        'role': 'owner',
      });
      expect(m.role, MemberRole.owner);
    });

    test('fromMap con role ausente usa member', () {
      final m = Member.fromMap('uid1', {'name': 'Bob', 'email': 'b@e.com'});
      expect(m.role, MemberRole.member);
    });

    test('fromMap con role desconocido usa member', () {
      final m = Member.fromMap('uid1', {'name': 'X', 'email': 'x@e.com', 'role': 'superadmin'});
      expect(m.role, MemberRole.member);
    });

    test('copyWith cambia solo el role', () {
      final original = _make(role: MemberRole.member);
      final promoted = original.copyWith(role: MemberRole.owner);
      expect(promoted.role, MemberRole.owner);
      expect(promoted.name, original.name);
      expect(promoted.memberId, original.memberId);
      expect(promoted.email, original.email);
    });

    test('round-trip toMap/fromMap conserva todos los campos', () {
      final original = _make(role: MemberRole.owner);
      final restored = Member.fromMap('uid1', original.toMap());
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.role, original.role);
    });
  });
}
