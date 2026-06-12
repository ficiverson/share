import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/models/expense.dart';

/// Parámetros para editar un gasto existente.
class EditExpenseParams {
  final String groupId;
  final Expense expense;

  EditExpenseParams({required this.groupId, required this.expense});
}

class EditExpenseUseCase extends BaseUseCase<EditExpenseParams, Expense> {
  final ExpensesRepositoryContract repository;

  EditExpenseUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<Expense>> _run() async {
    try {
      final p = params!;
      final expense = await repository.editExpense(p.groupId, p.expense);
      return Success(expense, Status.ok);
    } catch (e) {
      return Error(params!.expense, Status.fail, e.toString());
    }
  }
}
