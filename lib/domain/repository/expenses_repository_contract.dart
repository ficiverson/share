import 'package:share_app/models/expense.dart';

/// Contrato del repositorio de gastos. Implementado en
/// `data/expenses_repository.dart` (Fase 3).
abstract class ExpensesRepositoryContract {
  Future<List<Expense>> getExpenses(String groupSpreadsheetId);

  Future<Expense> addExpense(String groupSpreadsheetId, Expense expense);

  Future<Expense> editExpense(String groupSpreadsheetId, Expense expense);

  Future<void> deleteExpense(String groupSpreadsheetId, String expenseId);

  /// Importa un CSV exportado de Splitwise (ver sección 4 del plan):
  /// `Fecha, Descripción, Categoría, Coste, Moneda, <Miembro 1>, <Miembro 2>, ...`
  /// y vuelca las filas resultantes en las hojas Expenses/Splits.
  Future<int> importCsv(String groupSpreadsheetId, String csvContent);
}
