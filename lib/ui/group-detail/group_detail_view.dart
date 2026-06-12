import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/ui/expenses/expense_form_router.dart';
import 'package:share_app/ui/group-detail/group_detail_presenter.dart';
import 'package:share_app/utils/share_colors.dart';

/// Pantalla de detalle de un grupo: datos del grupo, `groupId` (para
/// invitar), miembros y lista de gastos en tiempo real. Permite añadir,
/// editar y borrar gastos, e importar un CSV exportado de Splitwise.
class GroupDetailView extends StatefulWidget {
  final String groupId;

  const GroupDetailView({super.key, required this.groupId});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> implements GroupDetailViewContract {
  late final GroupDetailPresenter _presenter;
  Group? _group;
  List<Expense>? _expenses;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    final injector = DependencyInjector.instance;
    _presenter = GroupDetailPresenter(
      this,
      groupsRepository: injector.groupsRepository,
      invoker: injector.invoker,
      watchExpensesUseCase: injector.watchExpensesUseCase,
      deleteExpenseUseCase: injector.deleteExpenseUseCase,
      importCsvUseCase: injector.importCsvUseCase,
    );
    _presenter.watchGroup(widget.groupId);
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  void onGroupChanged(Group group) {
    setState(() {
      _group = group;
      _error = null;
    });
  }

  @override
  void onGroupError(String error) {
    setState(() => _error = error);
  }

  @override
  void onExpensesChanged(List<Expense> expenses) {
    setState(() => _expenses = expenses);
  }

  @override
  void onExpensesError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
  }

  @override
  void onActionLoading(bool isLoading) {
    setState(() => _actionLoading = isLoading);
  }

  @override
  void onExpenseDeleted() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto eliminado')));
  }

  @override
  void onCsvImported(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count gastos importados')),
    );
  }

  @override
  void onActionError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
  }

  void _copyGroupId() {
    Clipboard.setData(ClipboardData(text: widget.groupId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID de grupo copiado')),
    );
  }

  String _memberName(String memberId) {
    final group = _group;
    if (group == null) return memberId;
    final member = group.members.where((m) => m.memberId == memberId);
    return member.isEmpty ? memberId : member.first.name;
  }

  Future<void> _addExpense() async {
    final group = _group;
    if (group == null) return;
    await ExpenseFormRouter.open(context, group);
  }

  Future<void> _editExpense(Expense expense) async {
    final group = _group;
    if (group == null) return;
    await ExpenseFormRouter.open(context, group, expense: expense);
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar gasto'),
        content: Text('¿Borrar "${expense.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.deleteExpense(widget.groupId, expense.expenseId);
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final fileBytes = result?.files.single.bytes;
    if (fileBytes == null) return;
    final csvContent = utf8.decode(fileBytes);
    _presenter.importCsv(widget.groupId, csvContent);
  }

  Widget _buildMembers(Group group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.tag, color: ShareColors.primary),
            title: const Text('ID del grupo'),
            subtitle: Text(group.groupId),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copiar ID',
              onPressed: _copyGroupId,
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.attach_money, color: ShareColors.primary),
            title: const Text('Moneda'),
            subtitle: Text(group.currency),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text('Miembros', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...group.members.map((member) => _MemberTile(member: member)),
      ],
    );
  }

  Widget _buildExpenses(Group group) {
    final expenses = _expenses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text('Gastos', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (expenses == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (expenses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Todavía no hay gastos en este grupo.'),
          )
        else
          ...expenses.map((expense) => Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: ShareColors.primary),
                  title: Text(expense.description.isEmpty ? '(sin descripción)' : expense.description),
                  subtitle: Text(
                    'Pagado por ${_memberName(expense.paidBy)} · ${expense.date.day}/${expense.date.month}/${expense.date.year}'
                    '${expense.category.isNotEmpty ? ' · ${expense.category}' : ''}',
                  ),
                  trailing: Text(
                    '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _editExpense(expense),
                  onLongPress: () => _deleteExpense(expense),
                ),
              )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? 'Grupo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar CSV de Splitwise',
            onPressed: _actionLoading ? null : _importCsv,
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: ShareColors.error)))
          : group == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_actionLoading) const LinearProgressIndicator(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildMembers(group),
                          _buildExpenses(group),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: group == null
          ? null
          : FloatingActionButton(
              onPressed: _actionLoading ? null : _addExpense,
              tooltip: 'Añadir gasto',
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null ? Text(member.name.isNotEmpty ? member.name[0] : '?') : null,
        ),
        title: Text(member.name),
        subtitle: Text(member.email),
      ),
    );
  }
}
