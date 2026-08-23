import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/add_expense_use_case.dart';
import 'package:share_app/domain/usecase/edit_expense_use_case.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/services/fcm_sender_service.dart';
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

  /// Escribe un doc de notificación personalizado en
  /// `notifications/{uid}/pending/` para cada miembro del grupo que no sea
  /// quien creó el gasto. El cuerpo incluye quién pagó y cuánto le toca
  /// pagar al destinatario según sus splits.
  Future<void> _sendNotifications(Group group, Expense expense) async {
    // Nombre(s) del pagador: lista de todos si hay pagos múltiples.
    final String payerNames;
    if (expense.payments.isNotEmpty) {
      payerNames = expense.payments
          .map((p) =>
              group.members
                  .where((m) => m.memberId == p.memberId)
                  .map((m) => m.name)
                  .firstOrNull ??
              p.memberId)
          .join(' y ');
    } else {
      payerNames = group.members
              .where((m) => m.memberId == expense.paidBy)
              .map((m) => m.name)
              .firstOrNull ??
          expense.paidBy;
    }

    for (final member in group.members) {
      if (member.memberId == expense.createdBy) continue;

      // Parte que le toca pagar a este miembro.
      final share = expense.splits
          .where((s) => s.memberId == member.memberId)
          .fold(0.0, (sum, s) => sum + s.shareAmount);

      final body = share > 0.001
          ? '$payerNames pagó ${expense.description} · te toca ${ShareFormat.money(share, expense.currency)}'
          : '$payerNames pagó ${expense.description} · ${ShareFormat.money(expense.amount, expense.currency)}';

      final notifTitle = 'Nuevo gasto en ${group.name}';
      final notifData = {
        'groupId': group.groupId,
        'expenseId': expense.expenseId,
      };

      // 1. Cloudflare Worker → FCM HTTP v1 → push en background/cerrada (móvil).
      final fcmToken = await firestoreDataSource.getFcmToken(member.memberId);
      if (fcmToken != null) {
        await FcmSenderService.instance.sendToToken(
          token: fcmToken,
          title: notifTitle,
          body: body,
          data: notifData,
        );
      }

      // 2. Firestore pending → listener local cuando la app está abierta o en web.
      try {
        await firestoreDataSource.sendNotificationToUser(member.memberId, {
          'title': notifTitle,
          'body': body,
          ...notifData,
        });
      } catch (_) {
        // Silencioso: fallo en notificación no bloquea la UI.
      }
    }
  }
}
