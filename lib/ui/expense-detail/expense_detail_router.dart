import 'package:flutter/material.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'expense_detail_view.dart';

class ExpenseDetailRouter {
  static Future<bool?> open(
    BuildContext context, {
    required Expense expense,
    required Group group,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailView(expense: expense, group: group),
      ),
    );
  }
}
