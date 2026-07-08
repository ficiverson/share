import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/utils/expense_category.dart';
import 'package:share_app/utils/share_colors.dart';
import 'package:share_app/utils/share_format.dart';

/// Pantalla de estadísticas de gasto para un grupo.
/// Recibe la lista de gastos ya cargada — no necesita presenter propio.
class StatsView extends StatefulWidget {
  final Group group;
  final List<Expense> expenses;

  const StatsView({super.key, required this.group, required this.expenses});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── agregaciones ──────────────────────────────────────────────────────────

  /// Gasto total por categoría, ordenado de mayor a menor.
  List<MapEntry<String, double>> get _byCategory {
    final map = <String, double>{};
    for (final e in widget.expenses) {
      final cat = e.category.isEmpty ? 'Sin categoría' : e.category;
      map[cat] = (map[cat] ?? 0) + e.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Gasto total por mes ('YYYY-MM'), ordenado cronológicamente.
  List<MapEntry<String, double>> get _byMonth {
    final map = <String, double>{};
    for (final e in widget.expenses) {
      final key = DateFormat('yyyy-MM').format(e.date);
      map[key] = (map[key] ?? 0) + e.amount;
    }
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  double get _totalSpent =>
      widget.expenses.fold(0.0, (sum, e) => sum + e.amount);

  // ─── widgets helpers ───────────────────────────────────────────────────────

  /// Barra horizontal con etiqueta y porcentaje.
  Widget _hBar({
    required String label,
    required double value,
    required double maxValue,
    required Color color,
    Widget? leading,
    String? sublabel,
  }) {
    final pct = maxValue > 0 ? value / maxValue : 0.0;
    final currency = widget.group.currency;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                ShareFormat.money(value, currency),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          if (sublabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(sublabel,
                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (_, constraints) {
            return Stack(
              children: [
                Container(
                  height: 10,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  height: 10,
                  width: constraints.maxWidth * pct.clamp(0.02, 1.0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Columna de barras verticales para el gráfico mensual.
  Widget _vBars(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return _emptyState();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final currency = widget.group.currency;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((entry) {
          final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
          // Formato: '2024-06' → 'jun 24'
          final parts = entry.key.split('-');
          final monthNum = int.tryParse(parts.last) ?? 1;
          final year = parts.first.substring(2);
          final monthLabel = DateFormat('MMM', 'es')
              .format(DateTime(2000, monthNum))
              .toLowerCase();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${entry.value.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 160 * pct.clamp(0.02, 1.0),
                  decoration: BoxDecoration(
                    color: ShareColors.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(monthLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                Text(year,
                    style: const TextStyle(fontSize: 10, color: Colors.black45)),
                const SizedBox(height: 2),
                Text(currency,
                    style: const TextStyle(fontSize: 9, color: Colors.black38)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.black26),
              SizedBox(height: 8),
              Text('No hay gastos todavía',
                  style: TextStyle(color: Colors.black45)),
            ],
          ),
        ),
      );

  // ─── tabs ──────────────────────────────────────────────────────────────────

  Widget _buildResumenTab() {
    final currency = widget.group.currency;
    final count = widget.expenses.length;
    final avg = count > 0 ? _totalSpent / count : 0.0;

    // mes con más gasto
    final byMonth = _byMonth;
    String? peakMonth;
    double peakAmt = 0;
    if (byMonth.isNotEmpty) {
      final peak = byMonth.reduce((a, b) => a.value > b.value ? a : b);
      peakMonth = peak.key;
      peakAmt = peak.value;
    }

    // categoría top
    final byCategory = _byCategory;
    final topCat = byCategory.isNotEmpty ? byCategory.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── tarjetas de resumen ──────────────────────────────────────────
        _summaryGrid(currency, count, avg, peakMonth, peakAmt, topCat),

        const SizedBox(height: 24),

        // ── mini preview por categoría ───────────────────────────────────
        if (byCategory.isNotEmpty) ...[
          const Text('Por categoría',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...byCategory.take(5).map((e) => _hBar(
                label: e.key,
                value: e.value,
                maxValue: _totalSpent,
                color: ShareColors.primary,
                leading: Icon(ExpenseCategory.icon(e.key),
                    size: 16, color: ShareColors.primary),
                sublabel: '${(e.value / _totalSpent * 100).toStringAsFixed(1)} %',
              )),
          if (byCategory.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${byCategory.length - 5} categorías más — ver pestaña Categorías',
                style:
                    const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
        ],
      ],
    );
  }

  Widget _summaryGrid(
    String currency,
    int count,
    double avg,
    String? peakMonth,
    double peakAmt,
    MapEntry<String, double>? topCat,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _metricCard(
          icon: Icons.euro,
          label: 'Total gastado',
          value: ShareFormat.money(_totalSpent, currency),
        ),
        _metricCard(
          icon: Icons.receipt_long,
          label: 'Nº gastos',
          value: '$count',
        ),
        _metricCard(
          icon: Icons.calculate,
          label: 'Importe medio',
          value: ShareFormat.money(avg, currency),
        ),
        if (peakMonth != null)
          _metricCard(
            icon: Icons.trending_up,
            label: 'Mes punta',
            value: peakMonth,
            sublabel: ShareFormat.money(peakAmt, currency),
          ),
        if (topCat != null)
          _metricCard(
            icon: ExpenseCategory.icon(topCat.key),
            label: 'Categoría top',
            value: topCat.key,
            sublabel: ShareFormat.money(topCat.value, currency),
          ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    String? sublabel,
  }) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: ShareColors.primary, size: 20),
              const SizedBox(height: 8),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              if (sublabel != null)
                Text(sublabel,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriasTab() {
    final entries = _byCategory;
    if (entries.isEmpty) return _emptyState();
    final maxVal = entries.first.value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${entries.length} categorías · '
          '${ShareFormat.money(_totalSpent, widget.group.currency)} total',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 16),
        ...entries.map((e) => _hBar(
              label: e.key,
              value: e.value,
              maxValue: maxVal,
              color: ShareColors.primary,
              leading: Icon(ExpenseCategory.icon(e.key),
                  size: 16, color: ShareColors.primary),
              sublabel: '${(e.value / _totalSpent * 100).toStringAsFixed(1)} % '
                  '· ${_expenseCountForCategory(e.key)} gasto${_expenseCountForCategory(e.key) == 1 ? '' : 's'}',
            )),
      ],
    );
  }

  int _expenseCountForCategory(String category) {
    return widget.expenses
        .where((e) => (e.category.isEmpty ? 'Sin categoría' : e.category) == category)
        .length;
  }

  Widget _buildMesesTab() {
    final entries = _byMonth;
    if (entries.isEmpty) return _emptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${entries.length} meses · '
            '${ShareFormat.money(_totalSpent, widget.group.currency)} total',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ),

        // Gráfico de barras verticales
        SizedBox(
          height: 220,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: _vBars(entries),
          ),
        ),

        const Divider(height: 24),

        // Lista detallada por mes
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: () {
              final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
              return entries.reversed.map((e) {
                // Formato legible: '2024-06' → 'junio 2024'
                final parts = e.key.split('-');
                final dt = DateTime(
                    int.parse(parts[0]), int.parse(parts[1]));
                final label = DateFormat('MMMM yyyy', 'es').format(dt);
                final count = widget.expenses
                    .where((ex) =>
                        DateFormat('yyyy-MM').format(ex.date) == e.key)
                    .length;
                return _hBar(
                  label: label,
                  value: e.value,
                  maxValue: maxVal,
                  color: ShareColors.accent,
                  sublabel: '$count gasto${count == 1 ? '' : 's'}',
                );
              }).toList();
            }(),
          ),
        ),
      ],
    );
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currency = widget.group.currency;
    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas · ${widget.group.name}'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumen'),
            Tab(icon: Icon(Icons.pie_chart_outline), text: 'Categorías'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Meses'),
          ],
        ),
      ),
      body: widget.expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart, size: 64, color: Colors.black26),
                  const SizedBox(height: 12),
                  const Text('Aún no hay gastos en este grupo.',
                      style: TextStyle(color: Colors.black45)),
                  const SizedBox(height: 4),
                  Text('Los totales aparecerán en $currency.',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black38)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _buildResumenTab(),
                _buildCategoriasTab(),
                _buildMesesTab(),
              ],
            ),
    );
  }
}
