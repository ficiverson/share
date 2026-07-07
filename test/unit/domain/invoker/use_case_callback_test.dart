import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/domain/invoker/use_case_callback.dart';
import 'package:share_app/domain/result/result.dart';

void main() {
  group('UseCaseCallback', () {
    test('inicia con tareas vacías', () {
      final cb = UseCaseCallback<String>();
      expect(cb.getTasks(), isEmpty);
    });

    test('addTask añade una tarea', () {
      final cb = UseCaseCallback<String>();
      cb.addTask(Future.value(Success('hello', Status.ok)));
      expect(cb.getTasks().length, 1);
    });

    test('clearTasks vacía la lista', () {
      final cb = UseCaseCallback<int>();
      cb.addTask(Future.value(Success(1, Status.ok)));
      cb.addTask(Future.value(Success(2, Status.ok)));
      cb.clearTasks();
      expect(cb.getTasks(), isEmpty);
    });

    test('getTasks devuelve las tareas añadidas en orden', () async {
      final cb = UseCaseCallback<int>();
      cb.addTask(Future.value(Success(1, Status.ok)));
      cb.addTask(Future.value(Success(2, Status.ok)));
      final tasks = cb.getTasks();
      expect(tasks.length, 2);
      final r1 = await tasks[0];
      final r2 = await tasks[1];
      expect(r1.data, 1);
      expect(r2.data, 2);
    });
  });
}
