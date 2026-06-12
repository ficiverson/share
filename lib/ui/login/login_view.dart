import 'package:flutter/material.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/user.dart';
import 'package:share_app/ui/login/login_presenter.dart';
import 'package:share_app/ui/login/login_router.dart';
import 'package:share_app/utils/share_colors.dart';

/// Pantalla de login. Implementa `LoginViewContract` (la interfaz definida
/// en el presenter) en el `State`, siguiendo el patrón MVP.
///
/// Permite iniciar sesión con Google o con email/contraseña (Firebase Auth),
/// y también registrarse con email/contraseña.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> implements LoginViewContract {
  late final LoginPresenter _presenter;
  bool _loading = true;
  String? _error;
  bool _registerMode = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final injector = DependencyInjector.instance;
    _presenter = LoginPresenter(
      this,
      invoker: injector.invoker,
      getCurrentUserUseCase: injector.getCurrentUserUseCase,
      signInWithGoogleUseCase: injector.signInWithGoogleUseCase,
      signInWithEmailUseCase: injector.signInWithEmailUseCase,
      signUpWithEmailUseCase: injector.signUpWithEmailUseCase,
    );
    _presenter.checkSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
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
  void onAuthLoading(bool isLoading) {
    setState(() {
      _loading = isLoading;
      if (isLoading) _error = null;
    });
  }

  @override
  void onAuthSuccess(AppUser user) {
    if (mounted) LoginRouter.goToGroups(context);
  }

  @override
  void onAuthError(String error) {
    setState(() => _error = error);
  }

  void _submitEmailForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Introduce email y contraseña');
      return;
    }
    if (_registerMode) {
      _presenter.signUpWithEmail(email, password, _nameController.text.trim());
    } else {
      _presenter.signInWithEmail(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
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
                        onPressed: _presenter.signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('Iniciar sesión con Google'),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('o con email'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_registerMode) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Contraseña'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitEmailForm,
                        child: Text(_registerMode ? 'Crear cuenta' : 'Iniciar sesión'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() {
                          _registerMode = !_registerMode;
                          _error = null;
                        }),
                        child: Text(
                          _registerMode
                              ? '¿Ya tienes cuenta? Inicia sesión'
                              : '¿No tienes cuenta? Regístrate',
                        ),
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
      ),
    );
  }
}
