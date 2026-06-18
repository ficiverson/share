import 'dart:async';

import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/calculate_balances_use_case.dart';
import 'package:share_app/domain/usecase/get_balances_use_case.dart';
import 'package:share_app/domain/usecase/settle_up_use_case.dart';
import 'package:share_app/domain/usecase/watch_settlements_use_case.dart';
import 'package:share_app/models/balance.dart';
import 'package:share_app/models/settlement.dart';

/// Vista abstracta que implementa el widget `BalancesView`.
abstract class BalancesViewContract {
  void onBalancesChanged(List<MemberBalance> balances, List<DebtTransfer> transfers);
  void onBalancesError(String error);
  void onSettling(bool isSettling);
  void onSettled(Settlement settlement);
  void onSettleError(String error);
}

class BalancesPresenter {
  final BalancesViewContract _view;
  final Invoker invoker;
  final GetBalancesUseCase getBalancesUseCase;
  final CalculateBalancesUseCase calculateBalancesUseCase;
  final WatchSettlementsUseCase watchSettlementsUseCase;
  final SettleUpUseCase settleUpUseCase;

  StreamSubscription<List<Settlement>>? _settlementsSubscription;
  String? _groupId;

  BalancesPresenter(
    this._view, {
    required this.invoker,
    required this.getBalancesUseCase,
    required this.calculateBalancesUseCase,
    required this.watchSettlementsUseCase,
    required this.settleUpUseCase,
  });

  /// Calcula los balances y se suscribe a las liquidaciones para recalcular
  /// en tiempo real cuando se registre una nueva.
  void watchBalances(String groupId) {
    _groupId = groupId;
    _loadBalances(groupId);

    _settlementsSubscription?.cancel();
    _settlementsSubscription = watchSettlementsUseCase.watch(groupId).listen((_) {
      _loadBalances(groupId);
    });
  }

  void _loadBalances(String groupId) {
    invoker.execute(getBalancesUseCase.withParams(groupId)).listen((balancesResult) {
      if (balancesResult is Error) {
        _view.onBalancesError((balancesResult as Error).getError());
        return;
      }
      final balances = (balancesResult as Success).getData() as List<MemberBalance>;

      invoker.execute(calculateBalancesUseCase.withParams(groupId)).listen((transfersResult) {
        if (transfersResult is Error) {
          _view.onBalancesError((transfersResult as Error).getError());
          return;
        }
        final transfers = (transfersResult as Success).getData() as List<DebtTransfer>;
        _view.onBalancesChanged(balances, transfers);
      });
    });
  }

  /// Registra una liquidación (p.ej. a partir de un [DebtTransfer]
  /// sugerido).
  void settleUp(DebtTransfer transfer) {
    final groupId = _groupId;
    if (groupId == null) return;
    _view.onSettling(true);
    invoker
        .execute(settleUpUseCase.withParams(SettleUpParams(
      groupId: groupId,
      settlement: Settlement(
        settlementId: '',
        fromMemberId: transfer.fromMemberId,
        toMemberId: transfer.toMemberId,
        amount: transfer.amount,
        date: DateTime.now(),
      ),
    )))
        .listen((result) {
      _view.onSettling(false);
      if (result is Success) {
        _view.onSettled(result.getData() as Settlement);
      } else {
        _view.onSettleError((result as Error).getError());
      }
    });
  }

  void dispose() {
    _settlementsSubscription?.cancel();
  }
}
