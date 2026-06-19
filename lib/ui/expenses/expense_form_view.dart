import 'package:flutter/material.dart' hide Split;
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/split.dart';
import 'package:share_app/ui/expenses/expense_form_presenter.dart';
import 'package:share_app/utils/share_colors.dart';

/// Formulario de alta/edición de un gasto. Reparto a partes iguales entre
/// los miembros seleccionados (todos por defecto).
class ExpenseFormView extends StatefulWidget {
  final Group group;
  final Expense? expense;

  const ExpenseFormView({super.key, required this.group, this.expense});

  @override
  State<ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends State<ExpenseFormView> implements ExpenseFormViewContract {
  late final ExpenseFormPresenter _presenter;

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  late TextEditingController _currencyController;

  String? _paidBy;
  late Set<String> _selectedMemberIds;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final injector = DependencyInjector.instance;
    _presenter = ExpenseFormPresenter(
      this,
      invoker: injector.invoker,
      addExpenseUseCase: injector.addExpenseUseCase,
      editExpenseUseCase: injector.editExpenseUseCase,
      firestoreDataSource: injector.firestoreDataSource,
    );

    final expense = widget.expense;
    _currencyController = TextEditingController(text: expense?.currency ?? widget.group.currency);
    if (expense != null) {
      _descriptionController.text = expense.description;
      _amountController.text = expense.amount.toString();
      _categoryController.text = expense.category;
      _notesController.text = expense.notes;
      _paidBy = expense.paidBy;
      _date = expense.date;
      _selectedMemberIds = expense.splits.map((s) => s.memberId).toSet();
    } else {
      _paidBy = widget.group.members.isNotEmpty ? widget.group.members.first.memberId : null;
      _selectedMemberIds = widget.group.members.map((m) => m.memberId).toSet();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  void onSaving(bool isSaving) {
    setState(() {
      _saving = isSaving;
      if (isSaving) _error = null;
    });
  }

  @override
  void onSaved(Expense expense) {
    if (mounted) Navigator.of(context).pop(expense);
  }

  @override
  void onSaveError(String error) {
    setState(() => _error = error);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (_descriptionController.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Introduce una descripción y un importe válido');
      return;
    }
    if (_paidBy == null || _selectedMemberIds.isEmpty) {
      setState(() => _error = 'Selecciona quién pagó y al menos un miembro para el reparto');
      return;
    }

    final shareAmount = amount / _selectedMemberIds.length;
    final splits = _selectedMemberIds
        .map((memberId) => Split(memberId: memberId, shareAmount: shareAmount, shareType: ShareType.equal))
        .toList();

    final uid = DependencyInjector.instance.authRepository.getCurrentUser()?.id ?? '';
    final expense = Expense(
      expenseId: widget.expense?.expenseId ?? '',
      description: _descriptionController.text.trim(),
      amount: amount,
      currency: _currencyController.text.trim().isEmpty
          ? widget.group.currency
          : _currencyController.text.trim().toUpperCase(),
      category: _categoryController.text.trim(),
      paidBy: _paidBy!,
      // Preservar createdBy original al editar; asignar uid actual al crear.
      createdBy: widget.expense?.createdBy.isNotEmpty == true
          ? widget.expense!.createdBy
          : uid,
      date: _date,
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      notes: _notesController.text.trim(),
      splits: splits,
    );

    _presenter.save(widget.group.groupId, expense, widget.group);
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;
    final isEdit = widget.expense != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar gasto' : 'Nuevo gasto')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Importe'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _currencyController,
                    decoration: const InputDecoration(labelText: 'Moneda'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paidBy,
              decoration: const InputDecoration(labelText: '¿Quién pagó?'),
              items: members
                  .map((m) => DropdownMenuItem(value: m.memberId, child: Text(m.name)))
                  .toList(),
              onChanged: (value) => setState(() => _paidBy = value),
            ),
            const SizedBox(height: 16),
            const Text('Repartir entre:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...members.map((member) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedMemberIds.contains(member.memberId),
                  title: Text(member.name),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedMemberIds.add(member.memberId);
                    } else {
                      _selectedMemberIds.remove(member.memberId);
                    }
                  }),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: ShareColors.error)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Guardar cambios' : 'Añadir gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
