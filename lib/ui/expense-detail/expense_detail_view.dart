import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/ui/expenses/expense_form_router.dart';
import 'package:share_app/utils/expense_category.dart';
import 'package:share_app/utils/share_colors.dart';

/// Pantalla de detalle de un gasto — solo lectura.
/// Muestra descripción, importe, pagador, fecha, categoría, notas y reparto.
/// Devuelve [true] si el gasto fue editado o borrado (para que el padre recargue).
class ExpenseDetailView extends StatelessWidget {
  const ExpenseDetailView({
    super.key,
    required this.expense,
    required this.group,
  });

  final Expense expense;
  final Group group;

  String _memberName(String uid) {
    try {
      return group.members.firstWhere((m) => m.id == uid).displayName;
    } catch (_) {
      return uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = DependencyInjector.instance.authRepository.getCurrentUser()?.id;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final icon = ExpenseCategory.icon(expense.category);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'es').format(expense.date);
    final fmt = NumberFormat.currency(symbol: '${expense.currency} ', decimalDigits: 2);

    // ¿Puede editar? El pagador, el creador o cualquiera (si queremos ser permisivos).
    // Por ahora: creador o pagador.
    final canEdit = uid == expense.paidBy || uid == expense.createdBy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del gasto'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar gasto',
              onPressed: () async {
                final saved = await ExpenseFormRouter.open(
                  context,
                  group,
                  expense: expense,
                );
                if (saved != null && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero card ─────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: ShareColors.primary.withOpacity(0.15),
                        child: Icon(icon, color: ShareColors.primary, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.description,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (expense.category.isNotEmpty)
                              Text(
                                expense.category,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    fmt.format(expense.amount),
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ShareColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Info rows ─────────────────────────────────────────────────────
          Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Pagó',
                  value: _memberName(expense.paidBy),
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha',
                  value: dateStr,
                ),
                if (expense.notes.isNotEmpty) ...[
                  const Divider(height: 1, indent: 56),
                  _InfoRow(
                    icon: Icons.notes_outlined,
                    label: 'Notas',
                    value: expense.notes,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Reparto ───────────────────────────────────────────────────────
          if (expense.splits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Reparto entre miembros',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < expense.splits.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 56),
                    _SplitRow(
                      name: _memberName(expense.splits[i].memberId),
                      amount: expense.splits[i].shareAmount,
                      currency: expense.currency,
                      isYou: expense.splits[i].memberId == uid,
                      isPayer: expense.splits[i].memberId == expense.paidBy,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widgets helper ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 20),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.name,
    required this.amount,
    required this.currency,
    required this.isYou,
    required this.isPayer,
  });

  final String name;
  final double amount;
  final String currency;
  final bool isYou;
  final bool isPayer;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '$currency ', decimalDigits: 2);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isPayer
                ? ShareColors.primary.withOpacity(0.15)
                : Theme.of(context).colorScheme.surfaceVariant,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isPayer ? ShareColors.primary : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isYou ? 'Tú${isPayer ? ' (pagador)' : ''}' : name + (isPayer ? ' (pagador)' : ''),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            fmt.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPayer ? ShareColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
