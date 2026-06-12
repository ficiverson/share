import 'package:csv/csv.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/split.dart';

/// Implementación de [ExpensesRepositoryContract] sobre Cloud Firestore.
class ExpensesRepository implements ExpensesRepositoryContract {
  final FirestoreRemoteDataSourceContract _remoteDataSource;

  ExpensesRepository({required FirestoreRemoteDataSourceContract remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<Expense>> watchExpenses(String groupId) => _remoteDataSource.watchExpenses(groupId);

  @override
  Future<List<Expense>> getExpenses(String groupId) => _remoteDataSource.getExpenses(groupId);

  @override
  Future<Expense> addExpense(String groupId, Expense expense) =>
      _remoteDataSource.addExpense(groupId, expense);

  @override
  Future<Expense> editExpense(String groupId, Expense expense) =>
      _remoteDataSource.updateExpense(groupId, expense);

  @override
  Future<void> deleteExpense(String groupId, String expenseId) =>
      _remoteDataSource.deleteExpense(groupId, expenseId);

  /// Importa un CSV exportado de Splitwise. Formato esperado (cabecera):
  /// `Fecha, Descripción, Categoría, Coste, Moneda, <Miembro 1>, <Miembro 2>, ...`
  ///
  /// Cada columna de miembro contiene el balance neto de esa persona para el
  /// gasto (positivo si "le deben", negativo si "debe"). Para mapear esto a
  /// nuestro modelo (reparto a partes iguales):
  /// - Se identifica a quien pagó como el miembro con el valor más alto
  ///   (normalmente positivo y cercano al coste total).
  /// - El reparto se hace a partes iguales entre todos los miembros con un
  ///   valor numérico en esa fila (no vacío).
  ///
  /// Los nombres de columna de miembro se cruzan (sin distinguir
  /// mayúsculas/acentos) con los nombres de los miembros del grupo; las
  /// columnas que no coincidan con ningún miembro se ignoran.
  @override
  Future<int> importCsv(String groupId, String csvContent) async {
    final group = await _remoteDataSource.watchGroup(groupId).first;
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(csvContent, fieldDelimiter: ',');
    if (rows.isEmpty) return 0;

    final header = rows.first.map((c) => c.toString().trim()).toList();
    final fixedColumns = {'fecha', 'descripción', 'descripcion', 'categoría', 'categoria', 'coste', 'moneda'};

    // Índices de las columnas de miembros, con su memberId asociado.
    final memberColumns = <int, String>{};
    for (var i = 0; i < header.length; i++) {
      final columnName = _normalize(header[i]);
      if (fixedColumns.contains(columnName)) continue;
      final member = group.members.firstWhereOrNull(
        (m) => _normalize(m.name) == columnName,
      );
      if (member != null) {
        memberColumns[i] = member.memberId;
      }
    }

    final dateIndex = header.indexWhere((h) => _normalize(h) == 'fecha');
    final descriptionIndex = header.indexWhere((h) => _normalize(h).startsWith('descripci'));
    final categoryIndex = header.indexWhere((h) => _normalize(h).startsWith('categor'));
    final costIndex = header.indexWhere((h) => _normalize(h) == 'coste');
    final currencyIndex = header.indexWhere((h) => _normalize(h) == 'moneda');

    final expensesToImport = <Expense>[];
    final now = DateTime.now();

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;

      final cost = double.tryParse(row[costIndex].toString().trim().replaceAll(',', '.'));
      if (cost == null) continue;

      // Valores numéricos por miembro presentes en esta fila.
      final memberValues = <String, double>{};
      for (final entry in memberColumns.entries) {
        if (entry.key >= row.length) continue;
        final raw = row[entry.key].toString().trim();
        if (raw.isEmpty) continue;
        final value = double.tryParse(raw.replaceAll(',', '.'));
        if (value != null) memberValues[entry.value] = value;
      }
      if (memberValues.isEmpty) continue;

      // Quien pagó = el miembro con el valor más alto.
      final paidBy = memberValues.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      final shareAmount = cost / memberValues.length;
      final splits = memberValues.keys
          .map((memberId) => Split(memberId: memberId, shareAmount: shareAmount, shareType: ShareType.equal))
          .toList();

      final date = dateIndex >= 0 ? _parseDate(row[dateIndex].toString().trim()) ?? now : now;

      expensesToImport.add(Expense(
        expenseId: '',
        description: descriptionIndex >= 0 ? row[descriptionIndex].toString().trim() : '',
        amount: cost,
        currency: currencyIndex >= 0 && currencyIndex < row.length
            ? row[currencyIndex].toString().trim()
            : group.currency,
        category: categoryIndex >= 0 ? row[categoryIndex].toString().trim() : '',
        paidBy: paidBy,
        date: date,
        createdAt: now,
        splits: splits,
      ));
    }

    if (expensesToImport.isEmpty) return 0;
    await _remoteDataSource.addExpensesBatch(groupId, expensesToImport);
    return expensesToImport.length;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  DateTime? _parseDate(String value) {
    // Soporta formatos comunes de Splitwise: DD/MM/YYYY o YYYY-MM-DD.
    if (value.isEmpty) return null;
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (isoMatch != null) {
      return DateTime(
        int.parse(isoMatch.group(1)!),
        int.parse(isoMatch.group(2)!),
        int.parse(isoMatch.group(3)!),
      );
    }
    final slashMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(value);
    if (slashMatch != null) {
      return DateTime(
        int.parse(slashMatch.group(3)!),
        int.parse(slashMatch.group(2)!),
        int.parse(slashMatch.group(1)!),
      );
    }
    return DateTime.tryParse(value);
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
