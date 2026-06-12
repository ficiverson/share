import 'package:share_app/models/group.dart';

/// Contrato del repositorio de grupos. Implementado en `data/groups_repository.dart`
/// (Fase 2), combinando el índice cacheado localmente con Drive/Sheets.
abstract class GroupsRepositoryContract {
  /// Lista los grupos del usuario (desde el índice en `appDataFolder`).
  Future<List<Group>> getGroups();

  /// Crea un nuevo Spreadsheet (hojas Info/Members/Expenses/Splits/Settlements),
  /// lo comparte con los emails indicados y lo añade al índice del usuario.
  Future<Group> createGroup({
    required String name,
    required String currency,
    required List<String> memberEmails,
  });

  /// Se une a un grupo existente a partir de su `spreadsheetId` y lo añade
  /// al índice del usuario.
  Future<Group> joinGroup(String spreadsheetId);
}
