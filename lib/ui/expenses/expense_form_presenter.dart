import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/add_expense_use_case.dart';
import 'package:share_app/domain/usecase/edit_expense_use_case.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/utils/share_format.dart';

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
  final FirestoreRemoteDataSourceContract firestoreDataSource;

  ExpenseFormPresenter(
    this._view, {
    required this.invoker,
    required this.addExpenseUseCase,
    required this.editExpenseUseCase,
    required this.firestoreDataSource,
  });

  /// Crea o actualiza un gasto.
  /// Al crear (no editar), envía notificaciones a todos los miembros del
  /// grupo excepto al que registró el gasto (`expense.createdBy`).
  void save(String groupId, Expense expense, Group group) {
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
        final saved = result.getData() as Expense;
        _view.onSaved(saved);
        if (!isEdit) _sendNotifications(group, saved);
      } else {
        _view.onSaveError((result as Error).getError());
      }
    });
  }

  /// Escribe un doc de notificación en `notifications/{uid}/pending/` para
  /// cada miembro del grupo que no sea quien creó el gasto.
  Future<void> _sendNotifications(Group group, Expense expense) async {
    final payerName = group.members
            .where((m) => m.memberId == expense.paidBy)
            .map((m) => m.name)
            .firstOrNull ??
        expense.paidBy;

    final payload = {
      'title': 'Nuevo gasto en ${group.name}',
      'body': '$payerName pagó ${expense.description} · ${ShareFormat.money(expense.amount, expense.currency)}',
      'groupId': group.groupId,
      'expenseId': expense.expenseId,
    };

    for (final member in group.members) {
      if (member.memberId == expense.createdBy) continue;
      try {
        await firestoreDataSource.sendNotificationToUser(
            member.memberId, payload);
      } catch (_) {
        // Silencioso: fallo en notificación no bloquea la UI.
      }
    }
  }
}
