import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/add_expense_use_case.dart';
import 'package:share_app/domain/usecase/edit_expense_use_case.dart';
import 'package:share_app/models/expense.dart';

/// Vista abstracta que implementa el widget `ExpenseFormView`.
abstract class ExpenseFormViewContract {
  void onSaving(bool isSaving);
  void onSaved(Expense expense);
  void onSaveError(String error);
}

class ExpenseFormPresenter {
  final ExpenseFormViewContract _view;
  final Invoker invoker;
  final AddExpenseUseCase addExpenseUseCase;
  final EditExpenseUseCase editExpenseUseCase;

  ExpenseFormPresenter(
    this._view, {
    required this.invoker,
    required this.addExpenseUseCase,
    required this.editExpenseUseCase,
  });

  /// Crea o actualiza un gasto según `expense.expenseId` esté vacío o no.
  void save(String groupId, Expense expense) {
    _view.onSaving(true);
    final isEdit = expense.expenseId.isNotEmpty;
    final stream = isEdit
        ? invoker.execute(editExpenseUseCase.withParams(
            EditExpenseParams(groupId: groupId, expense: expense),
          ))
        : invoker.execute(addExpenseUseCase.withParams(
            AddExpenseParams(groupId: groupId, expense: expense),
          ));

    stream.listen((result) {
      _view.onSaving(false);
      if (result is Success) {
        _view.onSaved(result.getData() as Expense);
      } else {
        _view.onSaveError((result as Error).getError());
      }
    });
  }
}
