import 'package:flutter/material.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/ui/balances/balances_view.dart';

/// Navegación de la pantalla "Saldos".
class BalancesRouter {
  static const String routeName = '/balances';

  static void open(BuildContext context, Group group) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BalancesView(group: group)),
    );
  }
}
