import 'package:flutter/material.dart';
import 'package:share_app/ui/groups/groups_view.dart';
import 'package:share_app/ui/login/login_view.dart';

/// Navegación de la pantalla de login.
class LoginRouter {
  static const String routeName = '/login';

  static Widget build() => const LoginView();

  /// Tras un login correcto, navega a la lista de grupos reemplazando la
  /// pantalla actual.
  static void goToGroups(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GroupsView()),
    );
  }
}
