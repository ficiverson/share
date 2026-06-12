import 'package:share_app/domain/result/result.dart';
import 'base_use_case.dart';

/// Ejecuta un [BaseUseCase] y emite cada [Result] encolado como un evento
/// de un `Stream<Result>`, en orden.
///
/// Uso típico desde un presenter:
/// ```dart
/// invoker.execute(getGroupsUseCase).listen((result) {
///   if (result is Success) {
///     view.onGroupsLoaded(result.getData());
///   } else {
///     view.onError((result as Error).getError());
///   }
/// });
/// ```
class Invoker {
  Stream<Result> execute(BaseUseCase useCase) async* {
    useCase.invoke();
    final tasks = List<Future<Result>>.from(useCase.callback.getTasks());
    useCase.callback.clearTasks();
    for (var task in tasks) {
      final result = await task;
      yield result;
    }
  }
}
