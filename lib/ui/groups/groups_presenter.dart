import 'dart:async';

import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/create_group_use_case.dart';
import 'package:share_app/domain/usecase/join_group_use_case.dart';
import 'package:share_app/domain/usecase/watch_groups_use_case.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/user.dart';

/// Vista abstracta que implementa el widget `GroupsView`.
abstract class GroupsViewContract {
  void onGroupsChanged(List<Group> groups);
  void onGroupsError(String error);
  void onActionLoading(bool isLoading);
  void onGroupCreated(Group group);
  void onGroupJoined(Group group);
  void onActionError(String error);
}

class GroupsPresenter {
  final GroupsViewContract _view;
  final Invoker invoker;
  final WatchGroupsUseCase watchGroupsUseCase;
  final CreateGroupUseCase createGroupUseCase;
  final JoinGroupUseCase joinGroupUseCase;

  StreamSubscription<List<Group>>? _groupsSubscription;

  GroupsPresenter(
    this._view, {
    required this.invoker,
    required this.watchGroupsUseCase,
    required this.createGroupUseCase,
    required this.joinGroupUseCase,
  });

  /// Empieza a escuchar en tiempo real los grupos del usuario.
  void watchGroups(AppUser user) {
    _groupsSubscription?.cancel();
    _groupsSubscription = watchGroupsUseCase.watch(user.id).listen(
      (groups) => _view.onGroupsChanged(groups),
      onError: (error) => _view.onGroupsError(error.toString()),
    );
  }

  /// Crea un nuevo grupo con el usuario actual como único miembro.
  void createGroup(AppUser user, String name, String currency) {
    _view.onActionLoading(true);
    invoker
        .execute(createGroupUseCase.withParams(CreateGroupParams(
      name: name,
      currency: currency,
      createdByUid: user.id,
      createdByName: user.displayName,
      createdByEmail: user.email,
      createdByPhotoUrl: user.photoUrl,
    )))
        .listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onGroupCreated(result.getData() as Group);
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  /// Une al usuario actual a un grupo existente a partir de su `groupId`.
  void joinGroup(AppUser user, String groupId) {
    _view.onActionLoading(true);
    invoker
        .execute(joinGroupUseCase.withParams(JoinGroupParams(
      groupId: groupId,
      memberUid: user.id,
      memberName: user.displayName,
      memberEmail: user.email,
      memberPhotoUrl: user.photoUrl,
    )))
        .listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onGroupJoined(result.getData() as Group);
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  void dispose() {
    _groupsSubscription?.cancel();
  }
}
