import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_view.dart';

/// PUT /me — change username and/or password.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: context.read<AuthProvider>().user?.username ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _errors = {});
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().updateProfile(
            username: _username.text,
            currentPassword: _current.text,
            password: _password.text,
            passwordConfirmation: _confirm.text,
          );
      if (!mounted) return;
      showSnack(context, 'Profile saved.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = {
            'username': e.fieldError('username'),
            'current_password': e.fieldError('current_password'),
            'password': e.fieldError('password'),
          });
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _username,
                  decoration: InputDecoration(labelText: 'Username', errorText: _errors['username']),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'At least 3 characters' : null,
                ),
                const SizedBox(height: 24),
                Text('Change password (optional)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Current password', errorText: _errors['current_password']),
                  validator: (v) => (_password.text.isNotEmpty && (v == null || v.isEmpty)) ? 'Enter your current password' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'New password', errorText: _errors['password']),
                  validator: (v) => (v != null && v.isNotEmpty && v.length < 8) ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                  validator: (v) => (_password.text.isNotEmpty && v != _password.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: busy ? null : _save, child: const Text('Save')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
