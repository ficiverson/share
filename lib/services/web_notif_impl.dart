// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Shows a browser system notification on web (foreground).
void showWebNotification(String title, String body) {
  html.Notification(title, body: body);
}
