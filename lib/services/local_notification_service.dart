import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio singleton que muestra notificaciones locales del sistema.
///
/// Uso:
/// ```dart
/// await LocalNotificationService.instance.init();
/// await LocalNotificationService.instance.show(title: '...', body: '...');
/// ```
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'share_expenses';
  static const _channelName = 'Gastos';
  static const _channelDesc = 'Notificaciones de nuevos gastos en tus grupos';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const macosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macosSettings,
      ),
    );

    // Canal Android con importancia alta (hace que aparezca el banner).
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Muestra una notificación del sistema con [title] y [body].
  /// [id] se genera automáticamente a partir del timestamp para evitar
  /// que notificaciones sucesivas se sobreescriban.
  Future<void> show({required String title, required String body}) async {
    if (!_initialized) await init();
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(
      id & 0x7FFFFFFF, // int32 positivo
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
    );
  }
}
