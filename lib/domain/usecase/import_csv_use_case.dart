import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

/// Parámetros para importar un CSV de Splitwise en un grupo.
class ImportCsvParams {
  final String groupId;
  final String csvContent;

  ImportCsvParams({required this.groupId, required this.csvContent});
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
      final count = await repository.importCsv(p.groupId, p.csvContent);
      return Success(count, Status.ok);
    } catch (e) {
      return Error(0, Status.fail, e.toString());
    }
  }
}
