import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';

/// Implementación de [GroupsRepositoryContract] sobre Cloud Firestore.
class GroupsRepository implements GroupsRepositoryContract {
  final FirestoreRemoteDataSourceContract _remoteDataSource;

  GroupsRepository({required FirestoreRemoteDataSourceContract remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<Group>> watchGroups(String uid) => _remoteDataSource.watchGroups(uid);

  @override
  Future<List<Group>> getGroups(String uid) => _remoteDataSource.getGroups(uid);

  @override
  Stream<Group> watchGroup(String groupId) => _remoteDataSource.watchGroup(groupId);

  @override
  Future<Group> createGroup({
    required String name,
    required String currency,
    required String createdByUid,
    required String createdByName,
    required String createdByEmail,
    String? createdByPhotoUrl,
  }) {
    final creator = Member(
      memberId: createdByUid,
      name: createdByName,
      email: createdByEmail,
      photoUrl: createdByPhotoUrl,
      joinedAt: DateTime.now(),
    );
    final group = Group(
      groupId: '',
      name: name,
      currency: currency,
      createdBy: createdByUid,
      createdAt: DateTime.now(),
      memberIds: [createdByUid],
      members: [creator],
    );
    return _remoteDataSource.createGroup(group);
  }

  @override
  Future<Group> joinGroup({
    required String groupId,
    required String memberUid,
    required String memberName,
    required String memberEmail,
    String? memberPhotoUrl,
  }) {
    final member = Member(
      memberId: memberUid,
      name: memberName,
      email: memberEmail,
      photoUrl: memberPhotoUrl,
      joinedAt: DateTime.now(),
    );
    return _remoteDataSource.addMember(groupId, member);
  }

  @override
  Future<void> leaveGroup(String groupId, String uid) =>
      _remoteDataSource.leaveGroup(groupId, uid);
}
