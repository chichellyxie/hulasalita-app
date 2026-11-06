import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../widgets/kwago.dart';
import '../../widgets/night_ui.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_view.dart';
import 'register_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  String? _loginError;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loginError = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().login(_login.text, _password.text);
      // AuthGate switches screens automatically.
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fieldError('login') != null) {
        setState(() => _loginError = e.fieldError('login'));
      } else {
        showSnack(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Night.bg,
      body: NightFormTheme(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(24, top + 40, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.headerTop, AppColors.headerBottom],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: const AppLogo(light: true, big: false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Kwago(message: 'Welcome back! Tara, hula tayo ng salita!'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _login,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Username or email',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        errorText: _loginError,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your username or email' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword ? 'Show password' : 'Hide password',
                          icon: Icon(_hidePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                    const SizedBox(height: 22),
                    GoldButton(label: 'Log in', icon: Icons.login_rounded, busy: busy, onPressed: _submit),
                    const SizedBox(height: 28),
                    NightCard(
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('New student? 🎒', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                                  Text("Join your school's leaderboard", style: TextStyle(color: Night.textMuted, fontSize: 13)),
                                ],
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.ink,
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: busy
                                  ? null
                                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: const Text('Create account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
