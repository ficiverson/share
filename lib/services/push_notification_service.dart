import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/services/local_notification_service.dart';
import 'package:share_app/services/web_notif.dart';

/// Gestiona las notificaciones push (FCM) en móvil.
///
/// - App abierta   → `onMessage` → muestra notificación local y borra el doc
///                   de Firestore para evitar que el listener de grupos
///                   lo muestre de nuevo.
/// - App en fondo  → FCM lo entrega al SO; el SO muestra el banner.
/// - App cerrada   → ídem.
/// - Web           → no hace nada; el listener de Firestore en `GroupsView`
///                   lo gestiona.
///
/// Inicializar llamando a [init] justo después del login.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // El SO ya muestra la notificación cuando la app está cerrada/en background.
  // No es necesario hacer nada aquí.
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  Future<void> init({
    required String uid,
    required FirestoreRemoteDataSourceContract dataSource,
  }) async {
    if (_initialized) return;
    _initialized = true;

    // Background handler (móvil/desktop; en web lo gestiona el service worker).
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    final messaging = FirebaseMessaging.instance;

    // Solicitar permiso (iOS/macOS; en Android ≥ 13; en web muestra el
    // diálogo del navegador).
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // En web se requiere la VAPID key para obtener el token.
    String? token;
    if (kIsWeb) {
      const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');
      if (vapidKey.isNotEmpty) {
        token = await messaging.getToken(vapidKey: vapidKey);
      }
    } else {
      token = await messaging.getToken();
    }
    if (token != null) {
      await dataSource.saveFcmToken(uid, token);
    }

    // Refrescar token si cambia (reinstalación, rotación de clave, etc.).
    messaging.onTokenRefresh.listen((newToken) async {
      try {
        await dataSource.saveFcmToken(uid, newToken);
      } catch (_) {}
    });

    // App en primer plano: mostrar notificación y borrar el doc de Firestore
    // para que el listener de GroupsView no lo duplique.
    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ??
          message.data['title'] as String? ??
          '';
      final body = message.notification?.body ??
          message.data['body'] as String? ??
          '';

      if (title.isNotEmpty || body.isNotEmpty) {
        if (kIsWeb) {
          showWebNotification(title, body);
        } else {
          await LocalNotificationService.instance.show(title: title, body: body);
        }
      }

      // Borrar el doc para que el listener de Firestore no lo muestre también.
      final docId = message.data['notifDocId'] as String?;
      if (docId != null) {
        try {
          await dataSource.deleteNotification(uid, docId);
        } catch (_) {}
      }
    });
  }
}
