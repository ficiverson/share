/// Contrato del datasource remoto de Google Sheets: creación del Spreadsheet
/// de un grupo con las hojas Info/Members/Expenses/Splits/Settlements, y
/// lectura/escritura de filas. Implementado en
/// `remote-data-source/google/sheets_remote_datasource.dart` (Fase 2/3)
/// usando `googleapis` (Sheets API v4).
abstract class SheetsRemoteDataSourceContract {
  /// Crea un Spreadsheet con las hojas estándar del grupo y devuelve su id.
  Future<String> createGroupSpreadsheet({
    required String name,
    required String currency,
    required String createdBy,
  });

  /// Lee todas las filas (sin encabezado) de una hoja.
  Future<List<List<dynamic>>> readSheet(String spreadsheetId, String sheetName);

  /// Añade una fila al final de una hoja.
  Future<void> appendRow(String spreadsheetId, String sheetName, List<dynamic> row);

  /// Añade varias filas al final de una hoja en una sola llamada (batchUpdate).
  Future<void> appendRows(
    String spreadsheetId,
    String sheetName,
    List<List<dynamic>> rows,
  );

  /// Actualiza una fila concreta (1-indexed, sin contar cabecera) de una hoja.
  Future<void> updateRow(
    String spreadsheetId,
    String sheetName,
    int rowIndex,
    List<dynamic> row,
  );

  /// Elimina una fila concreta (1-indexed, sin contar cabecera) de una hoja.
  Future<void> deleteRow(String spreadsheetId, String sheetName, int rowIndex);
}
