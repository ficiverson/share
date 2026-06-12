import 'package:share_app/models/group.dart';

/// Contrato del datasource local de grupos: caché del índice de grupos del
/// usuario (lista de spreadsheetIds + metadatos básicos), para no depender
/// de red en cada arranque. Implementado en Fase 2.
abstract class GroupsLocalDataSourceContract {
  Future<void> saveGroups(List<Group> groups);

  List<Group> getGroups();

  Future<void> clear();
}
