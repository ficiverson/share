import 'package:flutter/material.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/user.dart';
import 'package:share_app/ui/login/login_presenter.dart';
import 'package:share_app/ui/login/login_router.dart';
import 'package:share_app/utils/share_colors.dart';

/// Pantalla de login. Implementa `LoginViewContract` (la interfaz definida
/// en el presenter) en el `State`, siguiendo el patrón MVP.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> implements LoginViewContract {
  late final LoginPresenter _presenter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final injector = DependencyInjector.instance;
    _presenter = LoginPresenter(
      this,
      invoker: injector.invoker,
      getCurrentUserUseCase: injector.getCurrentUserUseCase,
      signInUseCase: injector.signInUseCase,
    );
    _presenter.checkSession();
  }

  @override
  void onSessionRestored(AppUser user) {
    setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) LoginRouter.goToGroups(context);
    });
  }

  @override
  void onNoSession() {
    setState(() => _loading = false);
  }

  @override
  void onSignInLoading(bool isLoading) {
    setState(() {
      _loading = isLoading;
      if (isLoading) _error = null;
    });
  }

  @override
  void onSignInSuccess(AppUser user) {
    if (mounted) LoginRouter.goToGroups(context);
  }

  @override
  void onSignInError(String error) {
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pie_chart, size: 96, color: ShareColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Share',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Divide gastos con tus grupos'),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _presenter.signIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión con Google'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: ShareColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
