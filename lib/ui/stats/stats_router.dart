import 'package:flutter/material.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/ui/stats/stats_view.dart';

class StatsRouter {
  static Future<void> open(
    BuildContext context, {
    required Group group,
    required List<Expense> expenses,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatsView(group: group, expenses: expenses),
      ),
    );
  }
}
