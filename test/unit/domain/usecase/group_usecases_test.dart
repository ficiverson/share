import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/create_group_use_case.dart';
import 'package:share_app/domain/usecase/delete_group_use_case.dart';
import 'package:share_app/domain/usecase/edit_group_use_case.dart';
import 'package:share_app/domain/usecase/join_group_use_case.dart';
import 'package:share_app/domain/usecase/leave_group_use_case.dart';
import 'package:share_app/domain/usecase/watch_groups_use_case.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';

// ── In-memory groups repo ─────────────────────────────────────────────────────
class _FakeGroupsRepo implements GroupsRepositoryContract {
  final List<Group> _store = [];
  bool shouldThrow = false;

  @override
  Stream<List<Group>> watchGroups(String uid) =>
      Stream.value(_store.where((g) => g.memberIds.contains(uid)).toList());

  @override
  Future<List<Group>> getGroups(String uid) async =>
      _store.where((g) => g.memberIds.contains(uid)).toList();

  @override
  Stream<Group> watchGroup(String groupId) =>
      Stream.value(_store.firstWhere((g) => g.groupId == groupId));

  @override
  Future<Group> createGroup({
    required String name,
    required String currency,
    required String createdByUid,
    required String createdByName,
    required String createdByEmail,
    String? createdByPhotoUrl,
  }) async {
    if (shouldThrow) throw Exception('create failed');
    final g = Group(
      groupId: 'g_${_store.length + 1}',
      name: name,
      currency: currency,
      createdBy: createdByUid,
      createdAt: DateTime(2024, 1, 1),
      memberIds: [createdByUid],
      members: [Member(memberId: createdByUid, name: createdByName, email: createdByEmail, joinedAt: DateTime(2024), role: MemberRole.owner)],
    );
    _store.add(g);
    return g;
  }

  @override
  Future<Group> joinGroup({required String groupId, required String memberUid, required String memberName, required String memberEmail, String? memberPhotoUrl}) async {
    if (shouldThrow) throw Exception('join failed');
    final i = _store.indexWhere((g) => g.groupId == groupId);
    if (i == -1) throw Exception('group not found');
    final g = _store[i];
    final newMember = Member(memberId: memberUid, name: memberName, email: memberEmail, joinedAt: DateTime(2024));
    final updated = g.copyWith(
      members: [...g.members, newMember],
      memberIds: [...g.memberIds, memberUid],
    );
    _store[i] = updated;
    return updated;
  }

  @override
  Future<void> leaveGroup(String groupId, String uid) async {
    if (shouldThrow) throw Exception('leave failed');
    final i = _store.indexWhere((g) => g.groupId == groupId);
    if (i == -1) return;
    final g = _store[i];
    _store[i] = g.copyWith(
      members: g.members.where((m) => m.memberId != uid).toList(),
      memberIds: g.memberIds.where((id) => id != uid).toList(),
    );
  }

  @override
  Future<void> updateGroup(String groupId, {required String name, required String currency}) async {
    if (shouldThrow) throw Exception('update failed');
    final i = _store.indexWhere((g) => g.groupId == groupId);
    if (i != -1) {
      final g = _store[i];
      _store[i] = Group(groupId: g.groupId, name: name, currency: currency, createdBy: g.createdBy, createdAt: g.createdAt, memberIds: g.memberIds, members: g.members);
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    if (shouldThrow) throw Exception('delete failed');
    _store.removeWhere((g) => g.groupId == groupId);
  }

  @override
  Future<void> updateUserNameInAllGroups(String uid, String name) async {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  late _FakeGroupsRepo repo;
  late Invoker invoker;

  setUp(() {
    repo = _FakeGroupsRepo();
    invoker = Invoker();
  });

  group('CreateGroupUseCase', () {
    test('éxito devuelve grupo con id y nombre', () async {
      final uc = CreateGroupUseCase(repository: repo)
        ..params = CreateGroupParams(name: 'Viaje', currency: 'EUR', createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      final g = results.first.data as Group;
      expect(g.name, 'Viaje');
      expect(g.currency, 'EUR');
      expect(g.createdBy, 'alice');
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = CreateGroupUseCase(repository: repo)
        ..params = CreateGroupParams(name: 'X', currency: 'EUR', createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('JoinGroupUseCase', () {
    setUp(() {
      repo._store.add(Group(groupId: 'g1', name: 'Grupo', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024), memberIds: ['alice'], members: [
        Member(memberId: 'alice', name: 'Alice', email: 'a@e.com', joinedAt: DateTime(2024), role: MemberRole.owner),
      ]));
    });

    test('éxito añade miembro al grupo', () async {
      final uc = JoinGroupUseCase(repository: repo)
        ..params = JoinGroupParams(groupId: 'g1', memberUid: 'bob', memberName: 'Bob', memberEmail: 'b@e.com');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      final g = results.first.data as Group;
      expect(g.memberIds, contains('bob'));
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = JoinGroupUseCase(repository: repo)
        ..params = JoinGroupParams(groupId: 'g1', memberUid: 'bob', memberName: 'Bob', memberEmail: 'b@e.com');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('LeaveGroupUseCase', () {
    setUp(() {
      repo._store.add(Group(groupId: 'g1', name: 'Grupo', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024), memberIds: ['alice', 'bob'], members: [
        Member(memberId: 'alice', name: 'Alice', email: 'a@e.com', joinedAt: DateTime(2024), role: MemberRole.owner),
        Member(memberId: 'bob', name: 'Bob', email: 'b@e.com', joinedAt: DateTime(2024)),
      ]));
    });

    test('éxito elimina al miembro del grupo', () async {
      final uc = LeaveGroupUseCase(repository: repo)
        ..params = LeaveGroupParams(groupId: 'g1', uid: 'bob');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect(repo._store.first.memberIds, isNot(contains('bob')));
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = LeaveGroupUseCase(repository: repo)
        ..params = LeaveGroupParams(groupId: 'g1', uid: 'bob');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('EditGroupUseCase', () {
    setUp(() {
      repo._store.add(Group(groupId: 'g1', name: 'Viejo', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024)));
    });

    test('éxito actualiza nombre y moneda', () async {
      final uc = EditGroupUseCase(repository: repo)
        ..params = EditGroupParams(groupId: 'g1', name: 'Nuevo', currency: 'USD');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect(repo._store.first.name, 'Nuevo');
      expect(repo._store.first.currency, 'USD');
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = EditGroupUseCase(repository: repo)
        ..params = EditGroupParams(groupId: 'g1', name: 'X', currency: 'EUR');
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('DeleteGroupUseCase', () {
    setUp(() {
      repo._store.add(Group(groupId: 'g1', name: 'Grupo', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024)));
    });

    test('éxito elimina el grupo', () async {
      final uc = DeleteGroupUseCase(repository: repo)..params = 'g1';
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect(repo._store, isEmpty);
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = DeleteGroupUseCase(repository: repo)..params = 'g1';
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('WatchGroupsUseCase', () {
    test('watch devuelve grupos del usuario', () async {
      repo._store.add(Group(groupId: 'g1', name: 'Grupo', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024), memberIds: ['alice']));
      final uc = WatchGroupsUseCase(repository: repo);
      final groups = await uc.watch('alice').first;
      expect(groups.length, 1);
      expect(groups.first.groupId, 'g1');
    });

    test('watch no devuelve grupos de otros usuarios', () async {
      repo._store.add(Group(groupId: 'g1', name: 'Grupo', currency: 'EUR', createdBy: 'alice', createdAt: DateTime(2024), memberIds: ['alice']));
      final uc = WatchGroupsUseCase(repository: repo);
      final groups = await uc.watch('bob').first;
      expect(groups, isEmpty);
    });
  });
}
