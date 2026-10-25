import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/school.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/reference_repository.dart';
import '../../widgets/error_view.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late Future<List<School>> _schoolsFuture;
  School? _school;
  bool _privacyAccepted = false;
  Map<String, String?> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _schoolsFuture = context.read<ReferenceRepository>().schools();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    if (_school == null) {
      showSnack(context, 'Please choose your school.', error: true);
      return;
    }
    if (!_privacyAccepted) {
      showSnack(context, 'Please read and accept the privacy notice.', error: true);
      return;
    }

    try {
      await context.read<AuthProvider>().register(
            username: _username.text,
            email: _email.text,
            password: _password.text,
            passwordConfirmation: _confirm.text,
            schoolId: _school!.id,
            privacyAccepted: _privacyAccepted,
          );
      // Status becomes "pending" → AuthGate opens the ID upload screen.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = {
            'username': e.fieldError('username'),
            'email': e.fieldError('email'),
            'password': e.fieldError('password'),
            'school_id': e.fieldError('school_id'),
          });
      showSnack(context, e.message, error: true);
    }
  }

  void _showPrivacyNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy notice'),
        content: const SingleChildScrollView(
          child: Text(
            'HulaSalita follows the Data Privacy Act of 2012 (RA 10173).\n\n'
            'We collect only what we need:\n'
            '• Username and email — to create your account and let you log in.\n'
            '• Your school — to place you on your school\'s leaderboard.\n'
            '• A photo of your school ID — only so the administrator can confirm you are a student.\n\n'
            'Your ID photo is stored privately, seen only by the administrator, and deleted as soon as your account is approved or rejected.\n\n'
            'Other students only see your username and points. Your real name is never required.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                  decoration: InputDecoration(
                    labelText: 'Username',
                    helperText: 'Shown on the leaderboard. Letters, numbers, - and _ only.',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    errorText: _serverErrors['username'],
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.length < 3) return 'At least 3 characters';
                    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) return 'Letters, numbers, - and _ only';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _serverErrors['email'],
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<School>>(
                  future: _schoolsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return ErrorView(
                        message: snapshot.error.toString(),
                        onRetry: () => setState(() {
                          _schoolsFuture = context.read<ReferenceRepository>().schools(refresh: true);
                        }),
                      );
                    }
                    final schools = snapshot.data ?? [];
                    return DropdownMenu<School>(
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('School in Urbiztondo'),
                      leadingIcon: const Icon(Icons.school_outlined),
                      errorText: _serverErrors['school_id'],
                      initialSelection: _school,
                      onSelected: (s) => setState(() => _school = s),
                      dropdownMenuEntries: schools
                          .map((s) => DropdownMenuEntry<School>(value: s, label: s.name))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 8 characters with letters and numbers',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _serverErrors['password'],
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.length < 8) return 'At least 8 characters';
                    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Use both letters and numbers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _privacyAccepted,
                  onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                  title: const Text('I have read and accept the privacy notice.'),
                  subtitle: GestureDetector(
                    onTap: _showPrivacyNotice,
                    child: const Text('Read the privacy notice',
                        style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
