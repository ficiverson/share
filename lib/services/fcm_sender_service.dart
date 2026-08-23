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
  FcmSenderService._();
  static final FcmSenderService instance = FcmSenderService._();

  /// Inyectado en build con --dart-define=FCM_WORKER_URL=https://...
  static const _workerUrl =
      String.fromEnvironment('FCM_WORKER_URL');

  /// Inyectado en build con --dart-define=FCM_SHARED_SECRET=...
  static const _sharedSecret =
      String.fromEnvironment('FCM_SHARED_SECRET');

  /// Envía una notificación push al [token] FCM indicado.
  /// No hace nada en web (las notificaciones web llegan por el listener de
  /// Firestore) ni si el Worker no está configurado aún.
  Future<void> sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (kIsWeb) return;
    if (_workerUrl.isEmpty) return;
    try {
      await http.post(
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
