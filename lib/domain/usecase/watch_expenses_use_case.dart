import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/models/expense.dart';

/// Expone en tiempo real los gastos de un grupo. Igual que
/// [WatchGroupsUseCase], se usa a través de [watch], no del [Invoker].
class WatchExpensesUseCase extends BaseUseCase<String, List<Expense>> {
  final ExpensesRepositoryContract repository;

  WatchExpensesUseCase({required this.repository});

  @override
  void invoke() {
    // No-op: ver [watch].
  }

  Stream<List<Expense>> watch(String groupId) => repository.watchExpenses(groupId);
}
