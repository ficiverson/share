import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/balance.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/settlement.dart';
import 'package:share_app/ui/balances/balances_presenter.dart';
import 'package:share_app/utils/share_colors.dart';

/// Pantalla "Saldos": balance neto por miembro y lista simplificada de
/// "quién debe a quién", con un botón para registrar cada liquidación.
class BalancesView extends StatefulWidget {
  final Group group;

  const BalancesView({super.key, required this.group});

  @override
  State<BalancesView> createState() => _BalancesViewState();
}

class _BalancesViewState extends State<BalancesView> implements BalancesViewContract {
  late final BalancesPresenter _presenter;
  List<MemberBalance>? _balances;
  List<DebtTransfer>? _transfers;
  String? _error;
  bool _settling = false;

  @override
  void initState() {
    super.initState();
    final injector = DependencyInjector.instance;
    _presenter = BalancesPresenter(
      this,
      invoker: injector.invoker,
      getBalancesUseCase: injector.getBalancesUseCase,
      calculateBalancesUseCase: injector.calculateBalancesUseCase,
      watchSettlementsUseCase: injector.watchSettlementsUseCase,
      settleUpUseCase: injector.settleUpUseCase,
    );
    _presenter.watchBalances(widget.group.groupId);
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  void onBalancesChanged(List<MemberBalance> balances, List<DebtTransfer> transfers) {
    setState(() {
      _balances = balances;
      _transfers = transfers;
      _error = null;
    });
  }

  @override
  void onBalancesError(String error) {
    setState(() => _error = error);
  }

  @override
  void onSettling(bool isSettling) {
    setState(() => _settling = isSettling);
  }

  @override
  void onSettled(Settlement settlement) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Liquidación registrada')),
    );
  }

  @override
  void onSettleError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
  }

  String _memberName(String memberId) {
    final member = widget.group.members.where((m) => m.memberId == memberId);
    return member.isEmpty ? memberId : member.first.name;
  }

  Future<void> _confirmSettle(DebtTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar liquidación'),
        content: Text(
          '${_memberName(transfer.fromMemberId)} paga '
          '${transfer.amount.toStringAsFixed(2)} ${widget.group.currency} a '
          '${_memberName(transfer.toMemberId)}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.settleUp(transfer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balances;
    final transfers = _transfers;
    final currency = widget.group.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Saldos')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: ShareColors.error)))
          : balances == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_settling) const LinearProgressIndicator(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text('Balance por persona', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...balances.map((balance) {
                      final net = balance.netAmount;
                      final isPositive = net > 0.01;
                      final isNegative = net < -0.01;
                      final color = isPositive
                          ? ShareColors.positive
                          : isNegative
                              ? ShareColors.negative
                              : null;
                      final label = isPositive
                          ? 'Le deben ${net.toStringAsFixed(2)} $currency'
                          : isNegative
                              ? 'Debe ${(-net).toStringAsFixed(2)} $currency'
                              : 'Al día';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person, color: ShareColors.primary),
                          title: Text(_memberName(balance.memberId)),
                          subtitle: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 24, 8, 8),
                      child: Text('Quién debe a quién', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (transfers == null || transfers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 48, color: ShareColors.positive),
                            SizedBox(height: 8),
                            Text('¡Todo está saldado! No hay deudas pendientes.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      )
                    else
                      ...transfers.map((transfer) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.arrow_forward, color: ShareColors.accent),
                              title: Text(
                                '${_memberName(transfer.fromMemberId)} → ${_memberName(transfer.toMemberId)}',
                              ),
                              subtitle: Text('${transfer.amount.toStringAsFixed(2)} $currency'),
                              trailing: TextButton(
                                onPressed: _settling ? null : () => _confirmSettle(transfer),
                                child: const Text('Liquidar'),
                              ),
                            ),
                          )),
                  ],
                ),
    );
  }
}
