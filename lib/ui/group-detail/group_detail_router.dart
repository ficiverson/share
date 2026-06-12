import 'package:flutter/material.dart';
import 'package:share_app/ui/group-detail/group_detail_view.dart';

/// Navegación de la pantalla de detalle de grupo.
class GroupDetailRouter {
  static const String routeName = '/group-detail';

  static Widget build(String groupId) => GroupDetailView(groupId: groupId);

  static void open(BuildContext context, String groupId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupDetailView(groupId: groupId)),
    );
  }
}
