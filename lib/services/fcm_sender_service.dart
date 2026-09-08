import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Envía notificaciones push a través del Cloudflare Worker `share-fcm-sender`.
///
/// El Worker genera el token OAuth 2.0 y llama FCM HTTP v1 internamente,
/// por lo que no es necesario exponer ninguna clave privada en el cliente.
///
/// ── Configuración ──────────────────────────────────────────────────────────
/// Los valores se inyectan en tiempo de compilación con --dart-define:
///
///   flutter build web --release \
///     --dart-define=FCM_WORKER_URL=https://share-fcm-sender.<user>.workers.dev \
///     --dart-define=FCM_SHARED_SECRET=<tu-secreto>
///
/// Para desarrollo local:
///   flutter run -d chrome \
///     --dart-define=FCM_WORKER_URL=... \
///     --dart-define=FCM_SHARED_SECRET=...
///
/// Nunca pongas los valores reales en el código fuente.
class FcmSenderService {
  FcmSenderService._({
    http.Client? client,
    String? workerUrl,
    String? sharedSecret,
  })  : _client = client ?? http.Client(),
        _workerUrl =
            workerUrl ?? const String.fromEnvironment('FCM_WORKER_URL'),
        _sharedSecret =
            sharedSecret ?? const String.fromEnvironment('FCM_SHARED_SECRET');

  static final FcmSenderService instance = FcmSenderService._();

  /// Constructor para tests: permite inyectar URL, secret y cliente HTTP.
  @visibleForTesting
  factory FcmSenderService.forTest({
    required String workerUrl,
    required String sharedSecret,
    required http.Client client,
  }) =>
      FcmSenderService._(
        workerUrl: workerUrl,
        sharedSecret: sharedSecret,
        client: client,
      );

  final http.Client _client;
  final String _workerUrl;
  final String _sharedSecret;

  /// Envía una notificación push al [token] FCM indicado.
  /// No hace nada si el Worker no está configurado (URL vacía).
  Future<void> sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (_workerUrl.isEmpty) return;
    try {
      await _client.post(
        Uri.parse(_workerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_sharedSecret',
        },
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': data,
        }),
      );
    } catch (_) {
      // Silencioso: un fallo de push no bloquea guardar el gasto.
    }
  }
}
