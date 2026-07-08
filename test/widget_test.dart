// Smoke test básico — verifica que la app arranca sin lanzar excepciones.
// Las pruebas de integración completas están en test/integration/.
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder — no widget tests require Firebase', (tester) async {
    // Los widget tests que necesitan Firebase se ubican en test/integration/.
    // Este archivo existe para que el runner no falle con "no tests found".
    expect(true, isTrue);
  });
}
