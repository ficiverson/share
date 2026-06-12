import 'package:flutter/material.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/ui/login/login_router.dart';
import 'package:share_app/utils/share_colors.dart';

/// Pantalla "Mis grupos" (placeholder de Fase 2). De momento muestra la
/// sesión activa y un botón de cerrar sesión.
class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final injector = DependencyInjector.instance;
    injector.invoker.execute(injector.signOutUseCase).listen((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginRouter.build()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = DependencyInjector.instance.authRepository.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signingOut ? null : _signOut,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group, size: 64, color: ShareColors.primary),
              const SizedBox(height: 16),
              if (user != null) Text('Hola, ${user.displayName}'),
              const SizedBox(height: 8),
              const Text(
                'Aquí aparecerán tus grupos.\n'
                '(Crear/listar grupos llega en la Fase 2)',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Crear grupo (Fase 2)',
        child: const Icon(Icons.add),
      ),
    );
  }
}
