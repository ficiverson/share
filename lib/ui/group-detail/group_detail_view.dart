import 'dart:convert';

import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/export_csv_use_case.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/balance.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/ui/balances/balances_router.dart';
import 'package:share_app/ui/csv_mapping/csv_mapping_dialog.dart';
import 'package:share_app/ui/stats/stats_router.dart';
import 'package:share_app/ui/expenses/expense_form_router.dart';
import 'package:share_app/ui/expense-detail/expense_detail_router.dart';
import 'package:share_app/ui/group-detail/group_detail_presenter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_app/utils/expense_category.dart';
import 'package:share_app/utils/share_colors.dart';
import 'package:share_app/utils/share_format.dart';

/// Pantalla de detalle de un grupo: datos del grupo, `groupId` (para
/// invitar), miembros y lista de gastos en tiempo real. Permite añadir,
/// editar y borrar gastos, e importar un CSV exportado de Split-styler.
class GroupDetailView extends StatefulWidget {
  final String groupId;

  const GroupDetailView({super.key, required this.groupId});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> implements GroupDetailViewContract {
  late final GroupDetailPresenter _presenter;
  late final ScrollController _scrollController;

  Group? _group;
  List<Expense>? _expenses;
  MemberBalance? _userBalance;
  String? _error;
  bool _actionLoading = false;

  /// Número de gastos que se muestran en pantalla (paginación cliente).
  int _displayLimit = 50;

  /// Controla la visibilidad del botón de volver al principio.
  bool _showScrollToTop = false;

  // ─── búsqueda ────────────────────────────────────────────────────────────
  bool _searchActive = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<Expense> get _filteredExpenses {
    final all = _expenses ?? [];
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((e) {
      if (e.description.toLowerCase().contains(q)) return true;
      if (e.category.toLowerCase().contains(q)) return true;
      final payer = _memberName(e.paidBy).toLowerCase();
      if (payer.contains(q)) return true;
      return false;
    }).toList();
  }

  // ─── helpers de paginación ───────────────────────────────────────────────

  List<Expense> get _displayedExpenses {
    final filtered = _filteredExpenses;
    return _searchQuery.isNotEmpty ? filtered : filtered.take(_displayLimit).toList();
  }

  bool get _hasMore => _searchQuery.isEmpty && (_expenses?.length ?? 0) > _displayLimit;

  // ─── lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    final injector = DependencyInjector.instance;
    _presenter = GroupDetailPresenter(
      this,
      groupsRepository: injector.groupsRepository,
      invoker: injector.invoker,
      watchExpensesUseCase: injector.watchExpensesUseCase,
      deleteExpenseUseCase: injector.deleteExpenseUseCase,
      deleteAllExpensesUseCase: injector.deleteAllExpensesUseCase,
      importCsvUseCase: injector.importCsvUseCase,
      leaveGroupUseCase: injector.leaveGroupUseCase,
      editGroupUseCase: injector.editGroupUseCase,
      deleteGroupUseCase: injector.deleteGroupUseCase,
      getUserBalanceUseCase: injector.getUserBalanceUseCase,
    );
    final uid = injector.authRepository.getCurrentUser()?.id;
    _presenter.watchGroup(widget.groupId, uid: uid);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _presenter.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;

    // Cargar más gastos al acercarse al final del scroll.
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMoreExpenses();
    }

    // Mostrar / ocultar botón de volver al principio.
    final shouldShow = pos.pixels > 300;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _loadMoreExpenses() {
    if (!_hasMore) return;
    setState(() => _displayLimit += 50);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ─── GroupDetailViewContract ──────────────────────────────────────────────

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
  void onUserBalanceLoaded(MemberBalance balance) {
    setState(() => _userBalance = balance);
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
  void onAllExpensesDeleted(int count) {
    setState(() => _displayLimit = 50);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count gastos eliminados')),
    );
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

  @override
  void onGroupLeft() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void onGroupUpdated() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grupo actualizado')),
    );
  }

  @override
  void onGroupDeleted() {
    if (mounted) Navigator.of(context).pop();
  }

  // ─── acciones ─────────────────────────────────────────────────────────────

  void _copyGroupId() {
    Clipboard.setData(ClipboardData(text: widget.groupId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID de grupo copiado')),
    );
  }

  Future<void> _showInviteSheet() async {
    final group = _group;
    if (group == null) return;
    final message =
        'Únete a mi grupo "${group.name}" en Share.\n\n'
        '1. Descarga la app\n'
        '2. Pulsa "Unirse a grupo"\n'
        '3. Introduce el ID: ${group.groupId}';

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invitar a miembros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Comparte el ID del grupo con quien quieras invitar. '
              'Deberá abrirlo en la app y pulsar "Unirse a grupo".',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ShareColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                group.groupId,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar ID'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.groupId));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ID copiado')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Mensaje copiado — pégalo en WhatsApp/etc.')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _memberName(String memberId) {
    final group = _group;
    if (group == null) return memberId;
    final member = group.members.where((m) => m.memberId == memberId);
    return member.isEmpty ? memberId : member.first.name;
  }

  /// Cuánto pagó realmente [uid] en este gasto (0 si no pagó nada).
  double _userPaidAmount(Expense expense, String uid) {
    if (expense.payments.isNotEmpty) {
      return expense.payments
          .where((p) => p.memberId == uid)
          .fold(0.0, (sum, p) => sum + p.shareAmount);
    }
    return expense.paidBy == uid ? expense.amount : 0.0;
  }

  /// Verdadero si [uid] pagó algo en este gasto (único o compartido).
  bool _isUserPayer(Expense expense, String uid) =>
      _userPaidAmount(expense, uid) > 0.001;

  /// Devuelve el color del importe de un gasto según la relación del usuario
  /// actual con él: verde si pagó más de lo que le toca, rojo si debe parte.
  Color? _expenseAmountColor(Expense expense, String? uid) {
    if (uid == null) return null;
    final paid = _userPaidAmount(expense, uid);
    final ownShare = expense.splits
        .where((s) => s.memberId == uid)
        .fold(0.0, (sum, s) => sum + s.shareAmount);
    if (paid > ownShare + 0.001) return ShareColors.positive;
    final inSplits =
        expense.splits.any((s) => s.memberId == uid && s.shareAmount > 0.001);
    if (inSplits) return ShareColors.negative;
    return null;
  }

  Future<void> _confirmDeleteAllExpenses() async {
    final expenses = _expenses;
    if (expenses == null || expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay gastos que borrar')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar todos los gastos'),
        content: Text(
          '¿Seguro que quieres eliminar los ${expenses.length} gastos de este grupo? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ShareColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.deleteAllExpenses(widget.groupId);
    }
  }

  Future<void> _showEditGroupDialog() async {
    final group = _group;
    if (group == null) return;
    final nameController = TextEditingController(text: group.name);
    final currencyController = TextEditingController(text: group.currency);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre del grupo'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currencyController,
              decoration: const InputDecoration(
                labelText: 'Moneda',
                hintText: 'EUR, USD, GBP...',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar')),
        ],
      ),
    );

    if (confirmed == true) {
      final name = nameController.text.trim();
      final currency = currencyController.text.trim().toUpperCase();
      if (name.isNotEmpty && currency.isNotEmpty) {
        _presenter.editGroup(widget.groupId, name: name, currency: currency);
      }
    }
  }

  Future<void> _confirmDeleteGroup() async {
    final group = _group;
    if (group == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar grupo'),
        content: Text(
          '¿Seguro que quieres borrar el grupo "${group.name}"? '
          'Se eliminarán todos sus gastos y liquidaciones. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ShareColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar grupo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.deleteGroup(widget.groupId);
    }
  }

  Future<void> _confirmLeaveGroup() async {
    final uid = DependencyInjector.instance.authRepository.getCurrentUser()?.id;
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text(
            '¿Seguro que quieres salir de este grupo? Perderás el acceso a sus gastos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ShareColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.leaveGroup(widget.groupId, uid);
    }
  }

  Future<void> _addExpense() async {
    final group = _group;
    if (group == null) return;
    await ExpenseFormRouter.open(context, group);
  }

  /// Devuelve true si el usuario actual puede editar o borrar [expense].
  /// Propietario del grupo → siempre. Miembro → solo sus gastos.
  bool _canModifyExpense(Expense expense) {
    final uid = DependencyInjector.instance.authRepository.getCurrentUser()?.id;
    if (uid == null) return false;
    final group = _group;
    if (group == null) return false;
    final isOwner = group.createdBy == uid;
    final isCreator = expense.createdBy == uid;
    final isPayer = uid != null && _isUserPayer(expense, uid);
    return isOwner || isCreator || isPayer;
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar gasto'),
        content: Text('¿Borrar "${expense.description}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.deleteExpense(widget.groupId, expense.expenseId);
    }
  }

  /// Extrae los nombres de columna de miembro del CSV de Split-styler.
  /// Formato de cabecera: Fecha, Descripción, Categoría, Coste, Moneda, <M1>, <M2>...
  List<String> _parseCsvMemberColumns(String csvContent) {
    final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];
    final header = lines.first.split(',').map((c) => c.trim()).toList();
    const fixedColumns = {
      'fecha',
      'descripción',
      'descripcion',
      'categoría',
      'categoria',
      'coste',
      'moneda'
    };
    return header
        .where((h) => !fixedColumns.contains(h.trim().toLowerCase()))
        .toList();
  }

  Future<void> _importCsv() async {
    final group = _group;
    if (group == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final fileBytes = result?.files.single.bytes;
    if (fileBytes == null) return;
    final csvContent = utf8.decode(fileBytes);

    final csvColumns = _parseCsvMemberColumns(csvContent);
    if (!mounted) return;

    Map<String, String>? columnMapping;
    if (csvColumns.isNotEmpty) {
      columnMapping = await CsvMappingDialog.show(
        context,
        csvColumns: csvColumns,
        members: group.members,
      );
      if (columnMapping == null) return;
    }

    _presenter.importCsv(widget.groupId, csvContent, columnMapping: columnMapping);
  }

  Future<void> _exportCsv() async {
    final group = _group;
    final expenses = _expenses;
    if (group == null || expenses == null || expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay gastos para exportar')),
      );
      return;
    }

    try {
      final injector = DependencyInjector.instance;
      final useCase = injector.exportCsvUseCase
          ..params = ExportCsvParams(group: group, expenses: expenses);
      String? csvContent;
      await for (final result in injector.invoker.execute(useCase)) {
        if (result.status == Status.ok) {
          csvContent = result.data as String?;
        }
      }
      if (csvContent == null) return;

      await Share.shareXFiles(
        [XFile.fromData(
          utf8.encode(csvContent),
          mimeType: 'text/csv',
        )],
        fileNameOverrides: ['${group.name}_gastos.csv'],
        subject: 'Gastos de ${group.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  // ─── widgets ──────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(Group group) {
    final expenses = _expenses ?? [];
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final userNet = _userBalance?.netAmount ?? 0.0;
    final netColor = userNet > 0.01
        ? ShareColors.positive
        : userNet < -0.01
            ? ShareColors.negative
            : null;
    final netLabel = userNet > 0.01
        ? 'Te deben ${ShareFormat.money(userNet, group.currency)}'
        : userNet < -0.01
            ? 'Debes ${ShareFormat.money(-userNet, group.currency)}'
            : 'Estás al día';

    return Card(
      color: ShareColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total gastado',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(
                    ShareFormat.money(totalSpent, group.currency),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${expenses.length} gasto${expenses.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (_userBalance != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Tu balance',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(
                    netLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: netColor ?? Colors.black87),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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

  /// Agrupa los gastos mostrados por mes (clave 'yyyy-MM') preservando orden.
  Map<String, List<Expense>> get _expensesByMonth {
    final result = <String, List<Expense>>{};
    for (final e in _displayedExpenses) {
      final key = DateFormat('yyyy-MM').format(e.date);
      (result[key] ??= []).add(e);
    }
    return result;
  }

  Widget _buildExpenses(Group group) {
    final expenses = _expenses;
    final uid = DependencyInjector.instance.authRepository.getCurrentUser()?.id;

    if (expenses == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black26),
            SizedBox(height: 8),
            Text('Todavía no hay gastos en este grupo.',
                style: TextStyle(color: Colors.black45)),
          ],
        ),
      );
    }

    final grouped = _expensesByMonth;
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      // ── Cabecera de mes ─────────────────────────────────────────────────
      final parts = entry.key.split('-');
      final monthDt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      final monthLabel = DateFormat('MMMM yyyy', 'es').format(monthDt);
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
          child: Text(
            monthLabel[0].toUpperCase() + monthLabel.substring(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );

      // ── Gastos del mes ────────────────────────────────────────────────
      for (final expense in entry.value) {
        widgets.add(_buildExpenseTile(expense, uid));
      }
    }

    // ── Footer de paginación ─────────────────────────────────────────────
    if (_hasMore) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: TextButton.icon(
              icon: const Icon(Icons.expand_more),
              label: Text(
                'Mostrando ${_displayedExpenses.length} de ${expenses.length}  •  Scroll para ver más',
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
              onPressed: _loadMoreExpenses,
            ),
          ),
        ),
      );
    } else if (expenses.length > 50) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              '${expenses.length} gastos en total',
              style: const TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Texto del subtítulo: quién pagó, con soporte para pagadores múltiples.
  String _payerLabel(Expense expense, String? uid) {
    final total = ShareFormat.money(expense.amount, expense.currency);
    if (expense.payments.isNotEmpty) {
      final isAnyPayer = uid != null &&
          expense.payments.any((p) => p.memberId == uid && p.shareAmount > 0.001);
      if (expense.payments.length == 1) {
        final p = expense.payments.first;
        final name = p.memberId == uid ? 'Tú' : _memberName(p.memberId);
        return '$name pagó $total';
      }
      if (isAnyPayer) {
        final others = expense.payments
            .where((p) => p.memberId != uid)
            .map((p) => _memberName(p.memberId))
            .join(', ');
        return 'Tú y $others pagasteis $total';
      } else {
        final names =
            expense.payments.map((p) => _memberName(p.memberId)).join(' y ');
        return '$names pagaron $total';
      }
    }
    final isYouSingle = expense.paidBy == uid;
    return isYouSingle
        ? 'Tú pagaste $total'
        : '${_memberName(expense.paidBy)} pagó $total';
  }

  Widget _buildExpenseTile(Expense expense, String? uid) {
    final amountColor = _expenseAmountColor(expense, uid);
    final icon = ExpenseCategory.icon(expense.category);
    final isYou = uid != null && _isUserPayer(expense, uid);
    final userNet = uid != null
        ? _userPaidAmount(expense, uid) -
            expense.splits
                .where((s) => s.memberId == uid)
                .fold(0.0, (sum, s) => sum + s.shareAmount)
        : 0.0;
    final amountLabel = isYou && userNet > 0.001
        ? 'prestaste'
        : expense.splits.any((s) => s.memberId == uid && s.shareAmount > 0.001)
            ? 'pediste prestado'
            : null;

    return InkWell(
      onTap: () async {
        final group = _group;
        if (group == null) return;
        await ExpenseDetailRouter.open(context, expense: expense, group: group);
      },
      onLongPress: _canModifyExpense(expense) ? () => _deleteExpense(expense) : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Fecha ──────────────────────────────────────────────────────
            SizedBox(
              width: 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM', 'es').format(expense.date).toLowerCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  Text(
                    DateFormat('d').format(expense.date),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Icono de categoría ─────────────────────────────────────────
            CircleAvatar(
              radius: 18,
              backgroundColor: ShareColors.primary.withValues(alpha: 0.10),
              child: Icon(icon, color: ShareColors.primary, size: 17),
            ),
            const SizedBox(width: 10),

            // ── Descripción + quién pagó ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expense.description.isEmpty ? '(sin descripción)' : expense.description,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _payerLabel(expense, uid),
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Importe coloreado + etiqueta ───────────────────────────────
            if (amountLabel != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountLabel,
                    style: TextStyle(fontSize: 10, color: amountColor ?? Colors.black45),
                  ),
                  Text(
                    _shareAmount(expense, uid),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Devuelve el importe neto del usuario en el gasto (pagado − parte propia).
  String _shareAmount(Expense expense, String? uid) {
    if (uid == null) return '';
    final paid = _userPaidAmount(expense, uid);
    final own = expense.splits
        .where((s) => s.memberId == uid)
        .fold(0.0, (sum, s) => sum + s.shareAmount);
    if (paid > 0.001) {
      // Pagador (único o compartido): muestra lo neto a favor
      return ShareFormat.money((paid - own).abs(), expense.currency);
    }
    // No pagó nada: muestra su parte a deber
    return ShareFormat.money(own, expense.currency);
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final group = _group;
    return Scaffold(
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white70,
                decoration: const InputDecoration(
                  hintText: 'Buscar gastos…',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              )
            : Text(group?.name ?? 'Grupo'),
        actions: [
          // Búsqueda — siempre visible
          IconButton(
            icon: Icon(_searchActive ? Icons.close : Icons.search),
            tooltip: _searchActive ? 'Cerrar búsqueda' : 'Buscar gastos',
            onPressed: () => setState(() {
              _searchActive = !_searchActive;
              if (!_searchActive) {
                _searchQuery = '';
                _searchController.clear();
              }
            }),
          ),
          if (!_searchActive) ...[
            // Saldos — siempre visible
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              tooltip: 'Ver saldos',
              onPressed: group == null ? null : () => BalancesRouter.open(context, group),
            ),
            // Menú ⋮ — todo lo demás
            Builder(builder: (context) {
              final uid = DependencyInjector.instance.authRepository.getCurrentUser()?.id;
              final isCreator = group != null && group.createdBy == uid;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'stats') {
                    if (group != null && _expenses != null) {
                      StatsRouter.open(context, group: group, expenses: _expenses!);
                    }
                  }
                  if (value == 'invite') _showInviteSheet();
                  if (value == 'editGroup') _showEditGroupDialog();
                  if (value == 'importCsv') _importCsv();
                  if (value == 'exportCsv') _exportCsv();
                  if (value == 'deleteAll') _confirmDeleteAllExpenses();
                  if (value == 'leave') _confirmLeaveGroup();
                  if (value == 'deleteGroup') _confirmDeleteGroup();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'stats',
                    child: Row(children: [
                      Icon(Icons.bar_chart),
                      SizedBox(width: 12),
                      Text('Estadísticas'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'invite',
                    child: Row(children: [
                      Icon(Icons.person_add_outlined),
                      SizedBox(width: 12),
                      Text('Invitar miembros'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'editGroup',
                    child: Row(children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text('Editar grupo'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'importCsv',
                    child: Row(children: [
                      Icon(Icons.upload_file_outlined),
                      SizedBox(width: 12),
                      Text('Importar CSV'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'exportCsv',
                    child: Row(children: [
                      Icon(Icons.download_outlined),
                      SizedBox(width: 12),
                      Text('Exportar CSV'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  if (isCreator)
                    const PopupMenuItem(
                      value: 'deleteAll',
                      child: Row(children: [
                        Icon(Icons.delete_sweep, color: ShareColors.error),
                        SizedBox(width: 12),
                        Text('Borrar todos los gastos',
                            style: TextStyle(color: ShareColors.error)),
                      ]),
                    ),
                  if (!isCreator)
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(children: [
                        Icon(Icons.exit_to_app, color: ShareColors.error),
                        SizedBox(width: 12),
                        Text('Salir del grupo',
                            style: TextStyle(color: ShareColors.error)),
                      ]),
                    ),
                  if (isCreator)
                    const PopupMenuItem(
                      value: 'deleteGroup',
                      child: Row(children: [
                        Icon(Icons.delete_forever, color: ShareColors.error),
                        SizedBox(width: 12),
                        Text('Borrar grupo',
                            style: TextStyle(color: ShareColors.error)),
                      ]),
                    ),
                ],
              );
            }),
          ],
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
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSummaryCard(group),
                          _buildMembers(group),
                          _buildExpenses(group),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),

      // Dos FABs: volver al principio (pequeño, condicional) + añadir gasto.
      floatingActionButton: group == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showScrollToTop) ...[
                  FloatingActionButton.small(
                    heroTag: 'scrollTop',
                    onPressed: _scrollToTop,
                    backgroundColor: Colors.white,
                    foregroundColor: ShareColors.primary,
                    tooltip: 'Volver al principio',
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton(
                  heroTag: 'addExpense',
                  onPressed: _actionLoading ? null : _addExpense,
                  tooltip: 'Añadir gasto',
                  child: const Icon(Icons.add),
                ),
              ],
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
          backgroundImage:
              member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null
              ? Text(member.name.isNotEmpty ? member.name[0] : '?')
              : null,
        ),
        title: Text(member.name),
        subtitle: Text(member.email),
      ),
    );
  }
}
