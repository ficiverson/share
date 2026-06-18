import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

/// Parámetros para importar un CSV de Splitwise en un grupo.
///
/// [columnMapping] es opcional: si se provee, indica qué columna CSV (por
/// nombre exacto) corresponde a qué miembro (por memberId). Si se omite,
/// `importCsv` usa la estrategia automática (nombre o posición).
class ImportCsvParams {
  final String groupId;
  final String csvContent;

  /// Mapeo explícito: csvColumnName → memberId.
  final Map<String, String>? columnMapping;

  ImportCsvParams({
    required this.groupId,
    required this.csvContent,
    this.columnMapping,
  });
}

/// Importa un CSV exportado de Splitwise. Devuelve el número de gastos
/// importados.
class ImportCsvUseCase extends BaseUseCase<ImportCsvParams, int> {
  final ExpensesRepositoryContract repository;

  ImportCsvUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<int>> _run() async {
    try {
      final p = params!;
      final count = await repository.importCsv(p.groupId, p.csvContent, columnMapping: p.columnMapping);
      return Success(count, Status.ok);
    } catch (e) {
      return Error(0, Status.fail, e.toString());
    }
  }
}
