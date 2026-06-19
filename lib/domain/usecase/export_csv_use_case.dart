import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';

class ExportCsvParams {
  final Group group;
  final List<Expense> expenses;
  ExportCsvParams({required this.group, required this.expenses});
}

/// Genera un String CSV con todos los gastos del grupo.
class ExportCsvUseCase extends BaseUseCase<ExportCsvParams, String> {
  ExportCsvUseCase({required ExpensesRepositoryContract repository})
      : _repository = repository;

  final ExpensesRepositoryContract _repository;

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<String>> _run() async {
    try {
      final p = params!;
      final csv = _repository.exportCsv(p.group, p.expenses);
      return Success(csv, Status.ok);
    } catch (e) {
      return Error('', Status.fail, e.toString());
    }
  }
}
