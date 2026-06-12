import 'package:flutter/material.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/ui/expenses/expense_form_view.dart';

/// Navegación del formulario de alta/edición de gasto.
class ExpenseFormRouter {
  static const String routeName = '/expense-form';

  /// Abre el formulario y devuelve el [Expense] guardado (o `null` si se
  /// canceló).
  static Future<Expense?> open(BuildContext context, Group group, {Expense? expense}) {
    return Navigator.of(context).push<Expense>(
      MaterialPageRoute(builder: (_) => ExpenseFormView(group: group, expense: expense)),
    );
  }
}
