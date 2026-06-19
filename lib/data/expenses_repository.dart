import 'package:csv/csv.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
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
  /// En el formato Splitwise, cada columna de miembro contiene el **balance
  /// neto** de esa persona: **negativo** si pagó (le deben), **positivo** si
  /// debe (se le cobró su parte). Por tanto, el pagador es el miembro con el
  /// valor más negativo.
  ///
  /// Estrategia de mapeo de columnas a miembros del grupo:
  /// 1. Intenta cruzar el nombre de columna con `member.name` (sin
  ///    mayúsculas/acentos).
  /// 2. Si ninguna columna coincide por nombre, usa el orden de posición:
  ///    columna N → member N del grupo (útil cuando los nombres difieren).
  @override
  Future<int> importCsv(String groupId, String csvContent, {Map<String, String>? columnMapping}) async {
    final group = await _remoteDataSource.watchGroup(groupId).first;

    // Normalizar saltos de línea (\r\n → \n) para compatibilidad Windows/Mac.
    final normalizedContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(normalizedContent, fieldDelimiter: ',');
    if (rows.isEmpty) return 0;

    // Saltar filas vacías al principio (Splitwise a veces añade una línea en blanco tras la cabecera).
    final nonEmptyRows = rows.where((r) => r.isNotEmpty && r.any((c) => c.toString().trim().isNotEmpty)).toList();
    if (nonEmptyRows.isEmpty) return 0;

    final header = nonEmptyRows.first.map((c) => c.toString().trim()).toList();
    final fixedColumns = {'fecha', 'descripción', 'descripcion', 'categoría', 'categoria', 'coste', 'moneda'};

    // Identificar índices de columnas que no son fijas (= columnas de miembros en el CSV).
    final csvMemberIndices = <int>[];
    for (var i = 0; i < header.length; i++) {
      if (!fixedColumns.contains(_normalize(header[i]))) {
        csvMemberIndices.add(i);
      }
    }

    // Construir índice columna → memberId.
    final memberColumns = <int, String>{};

    if (columnMapping != null && columnMapping.isNotEmpty) {
      // Mapeo explícito: csvColumnName → memberId (del diálogo de importación).
      for (final idx in csvMemberIndices) {
        final csvName = header[idx];
        final memberId = columnMapping[csvName];
        if (memberId != null) memberColumns[idx] = memberId;
      }
    } else {
      // 1) Intentar mapeo por nombre normalizado.
      for (final idx in csvMemberIndices) {
        final columnName = _normalize(header[idx]);
        final member = group.members.firstWhereOrNull(
          (m) => _normalize(m.name) == columnName,
        );
        if (member != null) memberColumns[idx] = member.memberId;
      }

      // 2) Fallback por posición si ningún nombre coincidió.
      if (memberColumns.isEmpty) {
        for (var j = 0; j < csvMemberIndices.length && j < group.members.length; j++) {
          memberColumns[csvMemberIndices[j]] = group.members[j].memberId;
        }
      }
    }

    final dateIndex = header.indexWhere((h) => _normalize(h) == 'fecha');
    final descriptionIndex = header.indexWhere((h) => _normalize(h).startsWith('descripci'));
    final categoryIndex = header.indexWhere((h) => _normalize(h).startsWith('categor'));
    final costIndex = header.indexWhere((h) => _normalize(h) == 'coste');
    final currencyIndex = header.indexWhere((h) => _normalize(h) == 'moneda');

    final expensesToImport = <Expense>[];
    final now = DateTime.now();

    for (final row in nonEmptyRows.skip(1)) {
      if (costIndex < 0 || costIndex >= row.length) continue;
      final cost = double.tryParse(row[costIndex].toString().trim().replaceAll(',', '.'));
      if (cost == null || cost == 0) continue;

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

      // En Splitwise, el pagador tiene el valor MÁS POSITIVO:
      // el CSV muestra el crédito/débito neto de cada persona por gasto.
      //   valor > 0 → pagó (crédito neto: pagó más de lo que le corresponde)
      //   valor < 0 → debe (débito neto: debe exactamente |valor|)
      //
      // Nota: la suma de todas las columnas de miembro para una fila es 0.
      final paidBy = memberValues.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      // Cálculo de la parte de cada persona:
      //   deudor (valor < 0): debe exactamente |valor|
      //   pagador (valor > 0): parte propia = coste − crédito_neto
      //
      // Ejemplo igual:  111 EUR, Gemma=+55.50, Iverson=-55.50
      //   → Gemma parte = 111 − 55.50 = 55.50   Iverson parte = 55.50
      // Ejemplo desigual: 50 EUR, Gemma=+50, Iverson=-50 (Gemma da efectivo a Iverson)
      //   → Gemma parte = 50 − 50 = 0   Iverson parte = 50
      final splits = memberValues.entries
          .map((entry) {
            final csvValue = entry.value;
            final share = csvValue < 0
                ? -csvValue            // deudor: debe exactamente el valor absoluto
                : cost - csvValue;     // pagador: parte propia = coste − crédito_neto
            return Split(
              memberId: entry.key,
              shareAmount: share < 0 ? 0 : share,
              shareType: ShareType.equal,
            );
          })
          .where((s) => s.shareAmount > 0.001) // ignorar partes cero
          .toList();

      final date = dateIndex >= 0 && dateIndex < row.length
          ? _parseDate(row[dateIndex].toString().trim()) ?? now
          : now;
      final currency = currencyIndex >= 0 && currencyIndex < row.length
          ? row[currencyIndex].toString().trim()
          : group.currency;
      final description = descriptionIndex >= 0 && descriptionIndex < row.length
          ? row[descriptionIndex].toString().trim()
          : '';
      final category = categoryIndex >= 0 && categoryIndex < row.length
          ? row[categoryIndex].toString().trim()
          : '';

      expensesToImport.add(Expense(
        expenseId: '',
        description: description,
        amount: cost,
        currency: currency.isEmpty ? group.currency : currency,
        category: category,
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

  @override
  Future<int> deleteAllExpenses(String groupId) =>
      _remoteDataSource.deleteAllExpenses(groupId);

  @override
  String exportCsv(Group group, List<Expense> expenses) {
    final members = group.members;

    // Cabecera: Date, Description, Category, Cost, Currency, paidBy, <member 1>, <member 2>, ...
    final header = [
      'Date',
      'Description',
      'Category',
      'Cost',
      'Currency',
      'PaidBy',
      ...members.map((m) => m.displayName),
    ];

    final rows = <List<dynamic>>[header];

    for (final e in expenses) {
      final row = <dynamic>[
        e.date.toIso8601String().substring(0, 10), // yyyy-MM-dd
        e.description,
        e.category,
        e.amount.toStringAsFixed(2),
        e.currency,
        members.firstWhere((m) => m.id == e.paidBy, orElse: () => members.first).displayName,
        // columna por miembro: su share o 0
        ...members.map((m) {
          final split = e.splits.where((s) => s.memberId == m.id).fold(0.0, (sum, s) => sum + s.shareAmount);
          return split.toStringAsFixed(2);
        }),
      ];
      rows.add(row);
    }

    return const ListToCsvConverter().convert(rows);
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
