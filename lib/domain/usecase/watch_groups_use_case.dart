import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/group.dart';

/// Devuelve un `Stream` con los grupos del usuario (`uid` como parámetro).
///
/// A diferencia del resto de casos de uso, este no se ejecuta a través del
/// [Invoker] (que devuelve un `Stream<Result>` de una sola pasada por tarea),
/// sino que expone directamente el stream de Firestore para que la UI pueda
/// suscribirse en tiempo real.
class WatchGroupsUseCase extends BaseUseCase<String, List<Group>> {
  final GroupsRepositoryContract repository;

  WatchGroupsUseCase({required this.repository});

  @override
  void invoke() {
    // No-op: este caso de uso se usa a través de [watch], no del Invoker.
  }

  /// Stream en tiempo real de los grupos donde `uid` es miembro.
  Stream<List<Group>> watch(String uid) => repository.watchGroups(uid);
}
