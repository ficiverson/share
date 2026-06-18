import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/repository/expenses_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';

class DeleteAllExpensesUseCase extends BaseUseCase<String, int> {
  final ExpensesRepositoryContract repository;

  DeleteAllExpensesUseCase({required this.repository});

  @override
  void invoke() {
    notifyListeners(_run());
  }

  Future<Result<int>> _run() async {
    try {
      final count = await repository.deleteAllExpenses(params!);
      return Success(count, Status.ok);
    } catch (e) {
      return Error(0, Status.fail, e.toString());
    }
  }
}
