import 'dart:async';

import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/repository/groups_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/delete_all_expenses_use_case.dart';
import 'package:share_app/domain/usecase/delete_expense_use_case.dart';
import 'package:share_app/domain/usecase/get_user_balance_use_case.dart';
import 'package:share_app/domain/usecase/import_csv_use_case.dart';
import 'package:share_app/domain/usecase/delete_group_use_case.dart';
import 'package:share_app/domain/usecase/edit_group_use_case.dart';
import 'package:share_app/domain/usecase/leave_group_use_case.dart';
import 'package:share_app/domain/usecase/watch_expenses_use_case.dart';
import 'package:share_app/models/balance.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';

/// Vista abstracta que implementa el widget `GroupDetailView`.
abstract class GroupDetailViewContract {
  void onGroupChanged(Group group);
  void onGroupError(String error);
  void onExpensesChanged(List<Expense> expenses);
  void onExpensesError(String error);
  void onUserBalanceLoaded(MemberBalance balance);
  void onActionLoading(bool isLoading);
  void onExpenseDeleted();
  void onAllExpensesDeleted(int count);
  void onCsvImported(int count);
  void onActionError(String error);
  void onGroupLeft();
  void onGroupUpdated();
  void onGroupDeleted();
}

class GroupDetailPresenter {
  final GroupDetailViewContract _view;
  final GroupsRepositoryContract groupsRepository;
  final Invoker invoker;
  final WatchExpensesUseCase watchExpensesUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final DeleteAllExpensesUseCase deleteAllExpensesUseCase;
  final ImportCsvUseCase importCsvUseCase;
  final LeaveGroupUseCase leaveGroupUseCase;
  final EditGroupUseCase editGroupUseCase;
  final DeleteGroupUseCase deleteGroupUseCase;
  final GetUserBalanceUseCase getUserBalanceUseCase;

  StreamSubscription<Group>? _groupSubscription;
  StreamSubscription<List<Expense>>? _expensesSubscription;

  GroupDetailPresenter(
    this._view, {
    required this.groupsRepository,
    required this.invoker,
    required this.watchExpensesUseCase,
    required this.deleteExpenseUseCase,
    required this.deleteAllExpensesUseCase,
    required this.importCsvUseCase,
    required this.leaveGroupUseCase,
    required this.editGroupUseCase,
    required this.deleteGroupUseCase,
    required this.getUserBalanceUseCase,
  });

  /// Empieza a escuchar en tiempo real los datos del grupo y sus gastos.
  /// [uid] es el id del usuario actual; si no es null, también refresca el
  /// balance propio cada vez que cambian los gastos.
  void watchGroup(String groupId, {String? uid}) {
    _groupSubscription?.cancel();
    _groupSubscription = groupsRepository.watchGroup(groupId).listen(
      (group) => _view.onGroupChanged(group),
      onError: (error) => _view.onGroupError(error.toString()),
    );

    _expensesSubscription?.cancel();
    _expensesSubscription = watchExpensesUseCase.watch(groupId).listen(
      (expenses) {
        _view.onExpensesChanged(expenses);
        if (uid != null) _refreshUserBalance(groupId, uid);
      },
      onError: (error) => _view.onExpensesError(error.toString()),
    );
  }

  void _refreshUserBalance(String groupId, String uid) {
    invoker
        .execute(getUserBalanceUseCase.withParams(
          GetUserBalanceParams(groupId: groupId, uid: uid),
        ))
        .listen((result) {
      if (result is Success) {
        _view.onUserBalanceLoaded(result.getData() as MemberBalance);
      }
      // error silencioso: la tarjeta simplemente no muestra balance personal
    });
  }

  void deleteExpense(String groupId, String expenseId) {
    _view.onActionLoading(true);
    invoker
        .execute(deleteExpenseUseCase.withParams(
      DeleteExpenseParams(groupId: groupId, expenseId: expenseId),
    ))
        .listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onExpenseDeleted();
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  void deleteAllExpenses(String groupId) {
    _view.onActionLoading(true);
    invoker.execute(deleteAllExpensesUseCase.withParams(groupId)).listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onAllExpensesDeleted(result.getData() as int);
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  void importCsv(String groupId, String csvContent, {Map<String, String>? columnMapping}) {
    _view.onActionLoading(true);
    invoker
        .execute(importCsvUseCase.withParams(
      ImportCsvParams(groupId: groupId, csvContent: csvContent, columnMapping: columnMapping),
    ))
        .listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onCsvImported(result.getData() as int);
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  void leaveGroup(String groupId, String uid) {
    _view.onActionLoading(true);
    invoker
        .execute(leaveGroupUseCase.withParams(
      LeaveGroupParams(groupId: groupId, uid: uid),
    ))
        .listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onGroupLeft();
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  void editGroup(String groupId, {required String name, required String currency}) {
    _view.onActionLoading(true);
    invoker
        .execute(editGroupUseCase.withParams(
      EditGroupParams(groupId: groupId, name: name, currency: currency),
    ))
        .listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onGroupUpdated();
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  void deleteGroup(String groupId) {
    _view.onActionLoading(true);
    invoker.execute(deleteGroupUseCase.withParams(groupId)).listen((result) {
      _view.onActionLoading(false);
      if (result is Success) {
        _view.onGroupDeleted();
      } else {
        _view.onActionError((result as Error).getError());
      }
    });
  }

  void dispose() {
    _groupSubscription?.cancel();
    _expensesSubscription?.cancel();
  }
}
