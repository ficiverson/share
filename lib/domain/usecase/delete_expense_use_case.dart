import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

/// Parámetros para borrar un gasto.
class DeleteExpenseParams {
  final String groupId;
  final String expenseId;

  DeleteExpenseParams({required this.groupId, required this.expenseId});
}

class DeleteExpenseUseCase extends BaseUseCase<DeleteExpenseParams, void> {
  final ExpensesRepositoryContract repository;

  DeleteExpenseUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<void>> _run() async {
    try {
      final p = params!;
      await repository.deleteExpense(p.groupId, p.expenseId);
      return Success(null, Status.ok);
    } catch (e) {
      return Error(null, Status.fail, e.toString());
    }
  }
}
