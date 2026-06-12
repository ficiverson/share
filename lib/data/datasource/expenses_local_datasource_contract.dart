import 'package:share_app/models/expense.dart';

/// Contrato del datasource local de gastos: caché de gastos por grupo, para
/// reducir lecturas a la Sheets API. Implementado en Fase 3.
abstract class ExpensesLocalDataSourceContract {
  Future<void> saveExpenses(String groupSpreadsheetId, List<Expense> expenses);

  List<Expense> getExpenses(String groupSpreadsheetId);

  Future<void> clear(String groupSpreadsheetId);
}
