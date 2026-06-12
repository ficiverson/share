import 'package:flutter/material.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/ui/login/login_router.dart';
import 'package:share_app/utils/share_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjector.instance.init();
  runApp(const ShareApp());
}

class ShareApp extends StatelessWidget {
  const ShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share',
      debugShowCheckedModeBanner: false,
      theme: ShareColors.theme(),
      home: LoginRouter.build(),
    );
  }
}
