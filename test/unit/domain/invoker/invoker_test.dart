import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/domain/invoker/base_use_case.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/result/result.dart';

// Caso de uso simple que dobla un número entero.
class DoubleUseCase extends BaseUseCase<int, int> {
  @override
  void invoke() {
    notifyListeners(Future.value(Success(params! * 2, Status.ok)));
  }
}

// Caso de uso que falla siempre.
class FailingUseCase extends BaseUseCase<void, String> {
  @override
  void invoke() {
    notifyListeners(Future.value(Error('', Status.fail, 'forced error')));
  }
}

// Caso de uso que emite dos resultados.
class TwoResultsUseCase extends BaseUseCase<void, int> {
  @override
  void invoke() {
    notifyListeners(Future.value(Success(1, Status.ok)));
    notifyListeners(Future.value(Success(2, Status.ok)));
  }
}

void main() {
  late Invoker invoker;

  setUp(() => invoker = Invoker());

  group('Invoker', () {
    test('execute emite el resultado de un use case exitoso', () async {
      final uc = DoubleUseCase()..params = 5;
      final results = await invoker.execute(uc).toList();
      expect(results.length, 1);
      expect(results.first.status, Status.ok);
      expect(results.first.data, 10);
    });

    test('execute emite Error cuando el use case falla', () async {
      final uc = FailingUseCase();
      final results = await invoker.execute(uc).toList();
      expect(results.length, 1);
      expect(results.first, isA<Error>());
      expect((results.first as Error).getError(), 'forced error');
    });

    test('execute emite múltiples resultados en orden', () async {
      final uc = TwoResultsUseCase();
      final results = await invoker.execute(uc).toList();
      expect(results.length, 2);
      expect(results[0].data, 1);
      expect(results[1].data, 2);
    });

    test('withParams asigna params y devuelve el mismo use case', () {
      final uc = DoubleUseCase();
      final returned = uc.withParams(7);
      expect(returned, same(uc));
      expect(uc.params, 7);
    });
  });
}
