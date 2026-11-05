import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/school.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/reference_repository.dart';
import '../../widgets/app_header.dart';
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
  String? _schoolLevel; // 'elementary' | 'high' — only filters the list, never saved
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
      body: Column(
        children: [
          AppHeader(
            title: 'Create account',
            showBack: true,
            child: const _StepBar(),
          ),
          Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
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
                    final all = snapshot.data ?? [];
                    final schools = switch (_schoolLevel) {
                      'elementary' => all.where((s) => s.hasElementary).toList(),
                      'high' => all.where((s) => s.hasHighSchool).toList(),
                      _ => <School>[],
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Where do you study?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF3A4060))),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'elementary', label: Text('Elementary'), icon: Icon(Icons.backpack_outlined)),
                            ButtonSegment(value: 'high', label: Text('High school'), icon: Icon(Icons.school_outlined)),
                          ],
                          emptySelectionAllowed: true,
                          showSelectedIcon: false,
                          selected: {if (_schoolLevel != null) _schoolLevel!},
                          onSelectionChanged: (sel) => setState(() {
                            _schoolLevel = sel.isEmpty ? null : sel.first;
                            // Clear a school that is not in the new list.
                            final keep = _school != null &&
                                ((_schoolLevel == 'elementary' && _school!.hasElementary) ||
                                    (_schoolLevel == 'high' && _school!.hasHighSchool));
                            if (!keep) _school = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        if (_schoolLevel == null)
                          const Text('Choose Elementary or High school first to see the schools.',
                              style: TextStyle(fontSize: 12, color: AppColors.muted))
                        else
                          DropdownMenu<School>(
                      key: ValueKey(_schoolLevel), // rebuild the menu when the filter changes
                      expandedInsets: EdgeInsets.zero,
                      // No typing: the list opens only when the student taps the field or the arrow.
                      enableFilter: false,
                      enableSearch: false,
                      requestFocusOnTap: false,
                      menuHeight: 320,
                      helperText: '${schools.length} ${_schoolLevel == 'elementary' ? 'elementary' : 'high'} schools · tap to choose',
                      label: const Text('School in Urbiztondo'),
                      leadingIcon: const Icon(Icons.school_outlined),
                      errorText: _serverErrors['school_id'],
                      initialSelection: _school,
                      onSelected: (s) => setState(() => _school = s),
                      dropdownMenuEntries: schools
                          .map((s) => DropdownMenuEntry<School>(value: s, label: s.name))
                          .toList(),
                          ),
                      ],
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.navySoft, borderRadius: BorderRadius.circular(18)),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Next, you'll upload a photo of your school ID. Only the administrator sees it, and it is deleted after review.",
                          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF2A2F4A)),
                        ),
                      ),
                    ],
                  ),
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
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "1 · Your account   2 · School ID photo" progress under the header.
class _StepBar extends StatelessWidget {
  const _StepBar();

  @override
  Widget build(BuildContext context) {
    Widget step(String label, bool active) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.gold : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : const Color(0xFFC9CDF2),
                  )),
            ],
          ),
        );
    return Row(children: [step('1 · Your account', true), const SizedBox(width: 8), step('2 · School ID photo', false)]);
  }
}
