import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/invoker/use_case_callback.dart';

/// Clase base de todos los casos de uso de la app.
///
/// Cada caso de uso concreto extiende `BaseUseCase<P, T>` (P = tipo de los
/// parámetros de entrada, T = tipo de dato devuelto), implementa [invoke] y
/// dentro de él llama a [notifyListeners] con un `Future<Result<T>>`. El
/// [Invoker] se encarga de ejecutar [invoke] y de transformar las tareas
/// encoladas en un `Stream<Result>`.
abstract class BaseUseCase<P, T> {
  P? params;
  UseCaseCallback callback = UseCaseCallback();

  void invoke();

  void notifyListeners(Future<Result<T>> task) {
    callback.addTask(task);
  }

  BaseUseCase<P, T> withParams(P params) {
    this.params = params;
    return this;
  }
}
