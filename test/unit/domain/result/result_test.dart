import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/domain/result/result.dart';

void main() {
  group('Result', () {
    test('Success tiene status ok y data correcta', () {
      final r = Success('hello', Status.ok);
      expect(r.status, Status.ok);
      expect(r.data, 'hello');
      expect(r.getData(), 'hello');
      expect(r.getStatus(), Status.ok);
      expect(r, isA<Success>());
    });

    test('Error tiene status fail y mensaje de error', () {
      final r = Error<String>('', Status.fail, 'algo salió mal');
      expect(r.status, Status.fail);
      expect(r.getError(), 'algo salió mal');
      expect(r, isA<Error>());
    });

    test('Status tiene valores ok y fail', () {
      expect(Status.values, containsAll([Status.ok, Status.fail]));
    });

    test('DataPolicy tiene tres valores', () {
      expect(DataPolicy.values, containsAll([DataPolicy.cache, DataPolicy.network, DataPolicy.networkCache]));
    });

    test('DataProvider tiene dos valores', () {
      expect(DataProvider.values, containsAll([DataProvider.local, DataProvider.network]));
    });

    test('Success hereda de Result', () {
      final r = Success(42, Status.ok);
      expect(r, isA<Result>());
    });

    test('Error hereda de Result', () {
      final r = Error<int>(0, Status.fail, 'err');
      expect(r, isA<Result>());
    });
  });
}
