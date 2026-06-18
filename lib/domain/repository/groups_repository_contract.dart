import 'package:share_app/models/group.dart';

/// Contrato del repositorio de grupos. Implementado en
/// `data/groups_repository.dart` (Fase 2) sobre Cloud Firestore: cada grupo
/// es un documento de la colección `groups`, con `memberIds` (uids) para
/// las reglas de seguridad y para filtrar `getGroups()`.
abstract class GroupsRepositoryContract {
  /// Stream con los grupos en los que el usuario indicado (uid) es miembro
  /// (`where('memberIds', arrayContains: uid)`).
  Stream<List<Group>> watchGroups(String uid);

  /// Lista puntual de los grupos del usuario.
  Future<List<Group>> getGroups(String uid);

  /// Crea un nuevo documento en `groups` con el creador como único miembro.
  Future<Group> createGroup({
    required String name,
    required String currency,
    required String createdByUid,
    required String createdByName,
    required String createdByEmail,
    String? createdByPhotoUrl,
  });

  /// Añade al usuario indicado (por uid) como miembro de un grupo existente.
  Future<Group> joinGroup({
    required String groupId,
    required String memberUid,
    required String memberName,
    required String memberEmail,
    String? memberPhotoUrl,
  });

  /// Stream con los datos de un grupo concreto (para la pantalla de detalle).
  Stream<Group> watchGroup(String groupId);

  /// Elimina al usuario indicado (uid) del grupo (de `memberIds` y `members`).
  Future<void> leaveGroup(String groupId, String uid);

  /// Actualiza el campo `name` del miembro (uid) en todos los grupos en los que participa.
  Future<void> updateUserNameInAllGroups(String uid, String name);
}
