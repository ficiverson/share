import 'package:share_app/models/expense.dart';

/// Contrato del repositorio de gastos. Implementado en
/// `data/expenses_repository.dart` (Fase 3) sobre la subcolección
/// `groups/{groupId}/expenses` de Firestore.
abstract class ExpensesRepositoryContract {
  /// Stream con los gastos del grupo, ordenados por fecha descendente.
  Stream<List<Expense>> watchExpenses(String groupId);

  Future<List<Expense>> getExpenses(String groupId);

  Future<Expense> addExpense(String groupId, Expense expense);

  Future<Expense> editExpense(String groupId, Expense expense);

  Future<void> deleteExpense(String groupId, String expenseId);

  /// Importa un CSV exportado de Splitwise (ver sección 4 del plan):
  /// `Fecha, Descripción, Categoría, Coste, Moneda, <Miembro 1>, <Miembro 2>, ...`
  /// y crea un documento de gasto (con sus `splits`) por cada fila.
  ///
  /// Si se pasa [columnMapping] (csvColumnName → memberId), se usa ese mapeo
  /// explícito en lugar de la detección automática por nombre/posición.
  Future<int> importCsv(String groupId, String csvContent, {Map<String, String>? columnMapping});

  /// Borra TODOS los gastos del grupo. Devuelve el número de gastos eliminados.
  Future<int> deleteAllExpenses(String groupId);
}
