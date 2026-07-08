import 'package:flutter/material.dart' hide Split;
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/split.dart';
import 'package:share_app/ui/expenses/expense_form_presenter.dart';
import 'package:share_app/utils/share_colors.dart';
import 'package:share_app/utils/share_format.dart';

/// Formulario de alta/edición de un gasto.
/// Soporta reparto igual o personalizado entre miembros,
/// y pago único o compartido entre varios pagadores.
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

  // Split personalizado (quién debe cuánto)
  bool _customSplit = false;
  final Map<String, TextEditingController> _splitControllers = {};

  // Pago compartido (quién pagó cuánto)
  bool _sharedPayment = false;
  late Set<String> _payingMemberIds;
  final Map<String, TextEditingController> _paymentControllers = {};

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

    // Inicializar controladores por miembro
    for (final m in widget.group.members) {
      _splitControllers[m.memberId] = TextEditingController();
      _paymentControllers[m.memberId] = TextEditingController();
    }

    if (expense != null) {
      _descriptionController.text = expense.description;
      _amountController.text = expense.amount.toString();
      _categoryController.text = expense.category;
      _notesController.text = expense.notes;
      _paidBy = expense.paidBy;
      _date = expense.date;
      _selectedMemberIds = expense.splits.map((s) => s.memberId).toSet();

      // Split personalizado
      final isCustom = expense.splits.any((s) => s.shareType == ShareType.exact);
      _customSplit = isCustom;
      if (isCustom) {
        for (final s in expense.splits) {
          _splitControllers[s.memberId]?.text = s.shareAmount.toStringAsFixed(2);
        }
      }

      // Pago compartido
      if (expense.payments.isNotEmpty) {
        _sharedPayment = true;
        _payingMemberIds = expense.payments.map((p) => p.memberId).toSet();
        for (final p in expense.payments) {
          _paymentControllers[p.memberId]?.text = p.shareAmount.toStringAsFixed(2);
        }
      } else {
        _payingMemberIds = {if (_paidBy != null) _paidBy!};
      }
    } else {
      _paidBy = widget.group.members.isNotEmpty ? widget.group.members.first.memberId : null;
      _selectedMemberIds = widget.group.members.map((m) => m.memberId).toSet();
      _payingMemberIds = {if (_paidBy != null) _paidBy!};
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _currencyController.dispose();
    for (final c in _splitControllers.values) c.dispose();
    for (final c in _paymentControllers.values) c.dispose();
    super.dispose();
  }

  @override
  void onSaving(bool isSaving) => setState(() {
        _saving = isSaving;
        if (isSaving) _error = null;
      });

  @override
  void onSaved(Expense expense) {
    if (mounted) Navigator.of(context).pop(expense);
  }

  @override
  void onSaveError(String error) => setState(() => _error = error);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Pre-rellena splits iguales cuando se activa reparto personalizado
  void _fillEqualSplits() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
    if (_selectedMemberIds.isEmpty) return;
    final share = amount / _selectedMemberIds.length;
    for (final id in _selectedMemberIds) {
      _splitControllers[id]?.text = share.toStringAsFixed(2);
    }
    for (final id in _splitControllers.keys) {
      if (!_selectedMemberIds.contains(id)) _splitControllers[id]?.text = '';
    }
  }

  /// Pre-rellena pagos iguales cuando se activa pago compartido
  void _fillEqualPayments() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
    if (_payingMemberIds.isEmpty) return;
    final share = amount / _payingMemberIds.length;
    for (final id in _payingMemberIds) {
      _paymentControllers[id]?.text = share.toStringAsFixed(2);
    }
    for (final id in _paymentControllers.keys) {
      if (!_payingMemberIds.contains(id)) _paymentControllers[id]?.text = '';
    }
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (_descriptionController.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Introduce una descripción y un importe válido');
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      setState(() => _error = 'Selecciona al menos un miembro para el reparto');
      return;
    }

    // ── Reparto (splits) ──────────────────────────────────────────────────
    List<Split> splits;
    if (_customSplit) {
      double total = 0;
      final customSplits = <Split>[];
      for (final id in _selectedMemberIds) {
        final val = double.tryParse(_splitControllers[id]?.text.trim().replaceAll(',', '.') ?? '');
        if (val == null || val < 0) {
          setState(() => _error = 'Introduce un importe válido para cada miembro del reparto');
          return;
        }
        total += val;
        customSplits.add(Split(memberId: id, shareAmount: val, shareType: ShareType.exact));
      }
      if ((total - amount).abs() > 0.02) {
        setState(() => _error =
            'La suma del reparto (${ShareFormat.amount(total)}) no coincide con el total (${ShareFormat.amount(amount)})');
        return;
      }
      splits = customSplits;
    } else {
      final shareAmount = amount / _selectedMemberIds.length;
      splits = _selectedMemberIds
          .map((id) => Split(memberId: id, shareAmount: shareAmount, shareType: ShareType.equal))
          .toList();
    }

    // ── Pagos (payments) ──────────────────────────────────────────────────
    List<Split> payments = [];
    String paidBy;

    if (_sharedPayment) {
      if (_payingMemberIds.isEmpty) {
        setState(() => _error = 'Selecciona al menos un pagador');
        return;
      }
      double total = 0;
      final paymentList = <Split>[];
      for (final id in _payingMemberIds) {
        final val = double.tryParse(_paymentControllers[id]?.text.trim().replaceAll(',', '.') ?? '');
        if (val == null || val < 0) {
          setState(() => _error = 'Introduce un importe válido para cada pagador');
          return;
        }
        total += val;
        paymentList.add(Split(memberId: id, shareAmount: val, shareType: ShareType.exact));
      }
      if ((total - amount).abs() > 0.02) {
        setState(() => _error =
            'La suma de los pagos (${ShareFormat.amount(total)}) no coincide con el total (${ShareFormat.amount(amount)})');
        return;
      }
      payments = paymentList;
      // paidBy = el que más pagó (para compatibilidad con vistas legacy)
      paidBy = paymentList.reduce((a, b) => a.shareAmount >= b.shareAmount ? a : b).memberId;
    } else {
      if (_paidBy == null) {
        setState(() => _error = 'Selecciona quién pagó');
        return;
      }
      paidBy = _paidBy!;
    }

    final uid = DependencyInjector.instance.authRepository.getCurrentUser()?.id ?? '';
    final expense = Expense(
      expenseId: widget.expense?.expenseId ?? '',
      description: _descriptionController.text.trim(),
      amount: amount,
      currency: _currencyController.text.trim().isEmpty
          ? widget.group.currency
          : _currencyController.text.trim().toUpperCase(),
      category: _categoryController.text.trim(),
      paidBy: paidBy,
      createdBy: widget.expense?.createdBy.isNotEmpty == true
          ? widget.expense!.createdBy
          : uid,
      date: _date,
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      notes: _notesController.text.trim(),
      splits: splits,
      payments: payments,
    );

    _presenter.save(widget.group.groupId, expense, widget.group);
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;
    final isEdit = widget.expense != null;
    final selectedMembers = members.where((m) => _selectedMemberIds.contains(m.memberId)).toList();
    final currency = _currencyController.text.trim().isNotEmpty
        ? _currencyController.text.trim().toUpperCase()
        : widget.group.currency;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar gasto' : 'Nuevo gasto')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Descripción ───────────────────────────────────────────────
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 8),

            // ── Importe + Moneda ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Importe'),
                    onChanged: (_) {
                      if (_customSplit) setState(() => _fillEqualSplits());
                      if (_sharedPayment) setState(() => _fillEqualPayments());
                    },
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

            // ── Categoría ─────────────────────────────────────────────────
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 8),

            // ── Fecha ─────────────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),

            // ── Sección pagador ───────────────────────────────────────────
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Pago compartido'),
                    subtitle: Text(
                      _sharedPayment
                          ? 'Varios miembros pusieron dinero'
                          : 'Un solo miembro pagó todo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    value: _sharedPayment,
                    activeColor: ShareColors.primary,
                    onChanged: (val) => setState(() {
                      _sharedPayment = val;
                      if (val) {
                        // Al activar: inicializar con el pagador actual
                        _payingMemberIds = {if (_paidBy != null) _paidBy!};
                        _fillEqualPayments();
                      }
                    }),
                  ),
                  if (!_sharedPayment)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: DropdownButtonFormField<String>(
                        value: _paidBy,
                        decoration: const InputDecoration(labelText: '¿Quién pagó?'),
                        items: members
                            .map((m) => DropdownMenuItem(value: m.memberId, child: Text(m.name)))
                            .toList(),
                        onChanged: (value) => setState(() => _paidBy = value),
                      ),
                    ),
                  if (_sharedPayment) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '¿Quién pagó cuánto?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    ...members.map((m) => Column(
                          children: [
                            CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              value: _payingMemberIds.contains(m.memberId),
                              title: Text(m.name),
                              activeColor: ShareColors.primary,
                              onChanged: (checked) => setState(() {
                                if (checked == true) {
                                  _payingMemberIds.add(m.memberId);
                                } else {
                                  _payingMemberIds.remove(m.memberId);
                                  _paymentControllers[m.memberId]?.text = '';
                                }
                                _fillEqualPayments();
                              }),
                            ),
                            if (_payingMemberIds.contains(m.memberId))
                              Padding(
                                padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
                                child: TextField(
                                  controller: _paymentControllers[m.memberId],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Pagó ${m.name}',
                                    suffixText: currency,
                                    prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                          ],
                        )),
                    // Indicador de suma de pagos
                    Builder(builder: (context) {
                      double total = 0;
                      for (final id in _payingMemberIds) {
                        total += double.tryParse(
                                _paymentControllers[id]?.text.trim().replaceAll(',', '.') ?? '') ??
                            0;
                      }
                      final target =
                          double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
                      final ok = target > 0 && (total - target).abs() <= 0.02;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              ok ? Icons.check_circle_outline : Icons.error_outline,
                              size: 16,
                              color: ok ? Colors.green : ShareColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pagado: ${ShareFormat.amount(total)} / ${ShareFormat.amount(target)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: ok ? Colors.green : ShareColors.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Selección de miembros para el reparto ─────────────────────
            const Text('Repartir entre:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...members.map((member) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedMemberIds.contains(member.memberId),
                  title: Text(member.name),
                  activeColor: ShareColors.primary,
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedMemberIds.add(member.memberId);
                    } else {
                      _selectedMemberIds.remove(member.memberId);
                      _splitControllers[member.memberId]?.text = '';
                    }
                    if (_customSplit) _fillEqualSplits();
                  }),
                )),
            const SizedBox(height: 8),

            // ── Toggle split personalizado ────────────────────────────────
            Card(
              child: SwitchListTile(
                title: const Text('Reparto personalizado'),
                subtitle: Text(
                  _customSplit
                      ? 'Indica el importe exacto de cada miembro'
                      : 'Reparto a partes iguales',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                value: _customSplit,
                activeColor: ShareColors.primary,
                onChanged: (val) => setState(() {
                  _customSplit = val;
                  if (val) _fillEqualSplits();
                }),
              ),
            ),

            // ── Campos de split personalizado ─────────────────────────────
            if (_customSplit) ...[
              const SizedBox(height: 8),
              ...selectedMembers.map((member) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _splitControllers[member.memberId],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: member.name,
                        suffixText: currency,
                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                      ),
                    ),
                  )),
              Builder(builder: (context) {
                double total = 0;
                for (final id in _selectedMemberIds) {
                  total += double.tryParse(
                          _splitControllers[id]?.text.trim().replaceAll(',', '.') ?? '') ??
                      0;
                }
                final target =
                    double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
                final ok = target > 0 && (total - target).abs() <= 0.02;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        ok ? Icons.check_circle_outline : Icons.error_outline,
                        size: 16,
                        color: ok ? Colors.green : ShareColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Suma: ${ShareFormat.amount(total)} / ${ShareFormat.amount(target)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: ok ? Colors.green : ShareColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // ── Notas ─────────────────────────────────────────────────────
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
