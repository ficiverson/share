/// Contrato del datasource remoto de Google Drive: creación de la carpeta
/// "Share App", creación de Spreadsheets dentro de ella, gestión de permisos
/// (compartir por email) y del índice de grupos en `appDataFolder`.
/// Implementado en `remote-data-source/google/drive_remote_datasource.dart`
/// (Fase 2) usando `googleapis` (Drive API v3).
abstract class DriveRemoteDataSourceContract {
  /// Devuelve el id de la carpeta "Share App" del usuario, creándola si no existe.
  Future<String> getOrCreateAppFolder();

  /// Comparte un archivo (Spreadsheet) con permiso de edición para el email indicado.
  Future<void> shareFile(String fileId, String email);

  /// Lee el índice de grupos (lista de spreadsheetIds) desde `appDataFolder`.
  Future<List<String>> getGroupIndex();

  /// Añade un spreadsheetId al índice de grupos en `appDataFolder`.
  Future<void> addToGroupIndex(String spreadsheetId);
}
