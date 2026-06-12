import 'package:share_app/domain/result/result.dart';

/// Cola de tareas (Futures) que un [BaseUseCase] añade durante su `invoke()`
/// y que el [Invoker] consume para emitirlas como [Result] en un Stream.
class UseCaseCallback<T> {
  List<Future<Result<T>>> tasks = [];

  void addTask(Future<Result<T>> task) {
    tasks.add(task);
  }

  List<Future<Result<T>>> getTasks() => tasks;

  void clearTasks() {
    tasks.clear();
  }
}
