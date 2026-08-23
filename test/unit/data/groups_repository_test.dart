import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/data/groups_repository.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';

// ── In-memory datasource ──────────────────────────────────────────────────────
class _FakeDS implements FirestoreRemoteDataSourceContract {
  final List<Group> _groups = [];

  @override
  Stream<List<Group>> watchGroups(String uid) =>
      Stream.value(_groups.where((g) => g.memberIds.contains(uid)).toList());

  @override
  Future<List<Group>> getGroups(String uid) async =>
      _groups.where((g) => g.memberIds.contains(uid)).toList();

  @override
  Stream<Group> watchGroup(String groupId) =>
      Stream.value(_groups.firstWhere((g) => g.groupId == groupId));

  @override
  Future<Group> createGroup(Group group) async {
    final saved = Group(
      groupId: 'g_${_groups.length + 1}',
      name: group.name, currency: group.currency, createdBy: group.createdBy,
      createdAt: group.createdAt, memberIds: group.memberIds, members: group.members,
    );
    _groups.add(saved);
    return saved;
  }

  @override
  Future<Group> addMember(String groupId, Member member) async {
    final i = _groups.indexWhere((g) => g.groupId == groupId);
    if (i == -1) throw Exception('not found');
    final g = _groups[i];
    final updated = g.copyWith(
      members: [...g.members, member],
      memberIds: [...g.memberIds, member.memberId],
    );
    _groups[i] = updated;
    return updated;
  }

  @override
  Future<void> leaveGroup(String groupId, String uid) async {
    final i = _groups.indexWhere((g) => g.groupId == groupId);
    if (i == -1) return;
    final g = _groups[i];
    _groups[i] = g.copyWith(
      members: g.members.where((m) => m.memberId != uid).toList(),
      memberIds: g.memberIds.where((id) => id != uid).toList(),
    );
  }

  @override
  Future<void> updateMemberName(String groupId, String uid, String name) async {
    final i = _groups.indexWhere((g) => g.groupId == groupId);
    if (i == -1) return;
    final g = _groups[i];
    _groups[i] = g.copyWith(
      members: g.members.map((m) => m.memberId == uid ? m.copyWith() : m).toList(),
    );
  }

  @override
  Future<void> updateGroup(String groupId, {required String name, required String currency}) async {
    final i = _groups.indexWhere((g) => g.groupId == groupId);
    if (i == -1) return;
    final g = _groups[i];
    _groups[i] = Group(
      groupId: g.groupId, name: name, currency: currency,
      createdBy: g.createdBy, createdAt: g.createdAt,
      memberIds: g.memberIds, members: g.members,
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async =>
      _groups.removeWhere((g) => g.groupId == groupId);

  @override Stream<List<Expense>> watchExpenses(String groupId) => Stream.value([]);
  @override Future<List<Expense>> getExpenses(String groupId) async => [];
  @override Future<Expense> addExpense(String groupId, Expense expense) async => expense;
  @override Future<Expense> updateExpense(String groupId, Expense expense) async => expense;
  @override Future<void> deleteExpense(String groupId, String expenseId) async {}
  @override Future<void> addExpensesBatch(String groupId, List<Expense> expenses) async {}
  @override Future<int> deleteAllExpenses(String groupId) async => 0;
  @override Stream<List<Settlement>> watchSettlements(String groupId) => Stream.value([]);
  @override Future<Settlement> addSettlement(String groupId, Settlement settlement) async => settlement;
  @override Future<void> saveFcmToken(String uid, String token) async {}
  @override Future<String?> getFcmToken(String uid) async => null;
  @override Future<void> sendNotificationToUser(String recipientUid, Map<String, dynamic> payload) async {}
  @override Stream<List<Map<String, dynamic>>> watchPendingNotifications(String uid) => Stream.value([]);
  @override Future<void> deleteNotification(String uid, String notificationId) async {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  late _FakeDS ds;
  late GroupsRepository repo;

  setUp(() {
    ds = _FakeDS();
    repo = GroupsRepository(remoteDataSource: ds);
  });

  group('GroupsRepository.createGroup', () {
    test('crea el grupo con nombre y moneda correctos', () async {
      final g = await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
      expect(g.name, 'Viaje');
      expect(g.currency, 'EUR');
    });

    test('el creador se añade con rol owner', () async {
      final g = await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
      expect(g.members.first.role, MemberRole.owner);
      expect(g.members.first.memberId, 'alice');
    });

    test('el grupo queda en la lista del creador', () async {
      await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
      final groups = await repo.getGroups('alice');
      expect(groups.length, 1);
    });
  });

  group('GroupsRepository.joinGroup', () {
    setUp(() async {
      await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
    });

    test('añade al miembro al grupo', () async {
      final groupId = ds._groups.first.groupId;
      final updated = await repo.joinGroup(
        groupId: groupId, memberUid: 'bob', memberName: 'Bob', memberEmail: 'b@e.com',
      );
      expect(updated.memberIds, contains('bob'));
    });

    test('el nuevo miembro tiene rol member por defecto', () async {
      final groupId = ds._groups.first.groupId;
      final updated = await repo.joinGroup(
        groupId: groupId, memberUid: 'bob', memberName: 'Bob', memberEmail: 'b@e.com',
      );
      final bob = updated.members.firstWhere((m) => m.memberId == 'bob');
      expect(bob.role, MemberRole.member);
    });
  });

  group('GroupsRepository.leaveGroup', () {
    setUp(() async {
      await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
      final groupId = ds._groups.first.groupId;
      await repo.joinGroup(
        groupId: groupId, memberUid: 'bob', memberName: 'Bob', memberEmail: 'b@e.com',
      );
    });

    test('elimina al miembro del grupo', () async {
      final groupId = ds._groups.first.groupId;
      await repo.leaveGroup(groupId, 'bob');
      expect(ds._groups.first.memberIds, isNot(contains('bob')));
    });
  });

  group('GroupsRepository.updateGroup', () {
    setUp(() async {
      await repo.createGroup(
        name: 'Viejo', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
    });

    test('actualiza nombre y moneda', () async {
      final groupId = ds._groups.first.groupId;
      await repo.updateGroup(groupId, name: 'Nuevo', currency: 'USD');
      expect(ds._groups.first.name, 'Nuevo');
      expect(ds._groups.first.currency, 'USD');
    });
  });

  group('GroupsRepository.deleteGroup', () {
    setUp(() async {
      await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
    });

    test('elimina el grupo de la lista', () async {
      final groupId = ds._groups.first.groupId;
      await repo.deleteGroup(groupId);
      expect(ds._groups, isEmpty);
    });
  });

  group('GroupsRepository.watchGroups', () {
    test('devuelve stream con grupos del usuario', () async {
      await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
      final groups = await repo.watchGroups('alice').first;
      expect(groups.length, 1);
    });

    test('no incluye grupos de otros usuarios', () async {
      await repo.createGroup(
        name: 'Viaje', currency: 'EUR',
        createdByUid: 'alice', createdByName: 'Alice', createdByEmail: 'a@e.com',
      );
      final groups = await repo.watchGroups('bob').first;
      expect(groups, isEmpty);
    });
  });
}
