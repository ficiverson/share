import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_app/services/fcm_sender_service.dart';

void main() {
  group('FcmSenderService', () {
    test('no hace nada cuando el Worker URL está vacío', () async {
      var called = false;
      final service = FcmSenderService.forTest(
        workerUrl: '',
        sharedSecret: 'secret',
        client: MockClient((_) async {
          called = true;
          return http.Response('', 200);
        }),
      );

      await service.sendToToken(token: 'tok', title: 'T', body: 'B');

      expect(called, isFalse);
    });

    test('hace POST al Worker con headers y body correctos', () async {
      http.Request? captured;
      final service = FcmSenderService.forTest(
        workerUrl: 'https://worker.example.dev/',
        sharedSecret: 'my-secret',
        client: MockClient((req) async {
          captured = req;
          return http.Response('ok', 200);
        }),
      );

      await service.sendToToken(
        token: 'device-token',
        title: 'Nuevo gasto',
        body: 'Alice pagó 30 €',
        data: {'groupId': 'g1'},
      );

      expect(captured, isNotNull);
      expect(captured!.url.toString(), 'https://worker.example.dev/');
      expect(captured!.headers['Authorization'], 'Bearer my-secret');
      expect(captured!.headers['Content-Type'], 'application/json');

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['token'], 'device-token');
      expect(body['title'], 'Nuevo gasto');
      expect(body['body'], 'Alice pagó 30 €');
      expect(body['data'], {'groupId': 'g1'});
    });

    test('traga excepciones en silencio sin lanzar', () async {
      final service = FcmSenderService.forTest(
        workerUrl: 'https://worker.example.dev/',
        sharedSecret: 'secret',
        client: MockClient((_) async => throw Exception('network error')),
      );

      await expectLater(
        service.sendToToken(token: 'tok', title: 'T', body: 'B'),
        completes,
      );
    });

    test('instancia singleton usa URL vacía en tests (sin --dart-define)', () async {
      // Verifica que el singleton no lanza aunque el Worker no esté configurado.
      await expectLater(
        FcmSenderService.instance
            .sendToToken(token: 'tok', title: 'T', body: 'B'),
        completes,
      );
    });
  });
}
