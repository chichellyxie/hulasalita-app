import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/admin_models.dart';
import '../../models/language.dart';
import '../../models/school.dart';
import '../../repositories/admin_repository.dart';
import '../../widgets/error_view.dart';

/// Entry point for schools, categories, languages and users.
class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String subtitle, Widget screen) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(icon, size: 32),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          ),
        );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        tile(Icons.school, 'Schools', 'Schools in Urbiztondo students can choose', const SchoolsAdminScreen()),
        tile(Icons.category, 'Categories', 'Home, School, Food, Nature…', const CategoriesAdminScreen()),
        tile(Icons.translate, 'Languages', 'English, Filipino, Pangasinan', const LanguagesAdminScreen()),
        tile(Icons.people, 'Users', 'Search, deactivate or reactivate accounts', const UsersAdminScreen()),
      ],
    );
  }
}

/// Text-field dialog helper. Returns the values, or null if cancelled.
Future<List<String>?> _textDialog(BuildContext context, {required String title, required List<String> labels, List<String>? initial}) {
  final controllers = List.generate(labels.length, (i) => TextEditingController(text: initial != null ? initial[i] : ''));
  return showDialog<List<String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(controller: controllers[i], decoration: InputDecoration(labelText: labels[i])),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, controllers.map((c) => c.text).toList()), child: const Text('Save')),
      ],
    ),
  );
}

// ---------------------------------------------------------------- Schools

class SchoolsAdminScreen extends StatefulWidget {
  const SchoolsAdminScreen({super.key});

  @override
  State<SchoolsAdminScreen> createState() => _SchoolsAdminScreenState();
}

class _SchoolsAdminScreenState extends State<SchoolsAdminScreen> {
  late Future<List<School>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminRepository>().schools();
  }

  void _reload() => setState(() => _future = context.read<AdminRepository>().schools());

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      showSnack(context, done);
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _edit([School? s]) async {
    final values = await _textDialog(context,
        title: s == null ? 'Add school' : 'Edit school', labels: const ['School name', 'Barangay'], initial: s == null ? null : [s.name, s.barangay ?? '']);
    if (values == null || values[0].trim().isEmpty || !mounted) return;
    await _run(
      () => context.read<AdminRepository>().saveSchool(id: s?.id, name: values[0], barangay: values[1], isActive: s?.isActive ?? true),
      'School saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schools')),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: FutureBuilder<List<School>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _reload);
          final schools = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: schools
                .map((s) => ListTile(
                      title: Text(s.name),
                      subtitle: Text('${s.barangay ?? '—'} · ${s.usersCount ?? 0} users'),
                      onTap: () => _edit(s),
                      onLongPress: () async {
                        final ok = await confirmDialog(context, title: 'Delete school?', message: s.name, confirmLabel: 'Delete');
                        if (ok && context.mounted) {
                          await _run(() => context.read<AdminRepository>().deleteSchool(s.id), 'School deleted.');
                        }
                      },
                      trailing: Switch(
                        value: s.isActive,
                        onChanged: (v) => _run(
                          () => context.read<AdminRepository>().saveSchool(id: s.id, name: s.name, barangay: s.barangay, isActive: v),
                          v ? 'School activated.' : 'School hidden from registration.',
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- Categories

class CategoriesAdminScreen extends StatefulWidget {
  const CategoriesAdminScreen({super.key});

  @override
  State<CategoriesAdminScreen> createState() => _CategoriesAdminScreenState();
}

class _CategoriesAdminScreenState extends State<CategoriesAdminScreen> {
  late Future<List<PuzzleCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminRepository>().categories();
  }

  void _reload() => setState(() => _future = context.read<AdminRepository>().categories());

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      showSnack(context, done);
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _edit([PuzzleCategory? c]) async {
    final values = await _textDialog(context,
        title: c == null ? 'Add category' : 'Edit category', labels: const ['Name'], initial: c == null ? null : [c.name]);
    if (values == null || values[0].trim().isEmpty || !mounted) return;
    await _run(() => context.read<AdminRepository>().saveCategory(id: c?.id, name: values[0]), 'Category saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: FutureBuilder<List<PuzzleCategory>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _reload);
          return ListView(
            children: (snapshot.data ?? [])
                .map((c) => ListTile(
                      title: Text(c.name),
                      onTap: () => _edit(c),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await confirmDialog(context, title: 'Delete category?', message: c.name, confirmLabel: 'Delete');
                          if (ok && context.mounted) {
                            await _run(() => context.read<AdminRepository>().deleteCategory(c.id), 'Category deleted.');
                          }
                        },
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- Languages

class LanguagesAdminScreen extends StatefulWidget {
  const LanguagesAdminScreen({super.key});

  @override
  State<LanguagesAdminScreen> createState() => _LanguagesAdminScreenState();
}

class _LanguagesAdminScreenState extends State<LanguagesAdminScreen> {
  late Future<List<Language>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminRepository>().languages();
  }

  void _reload() => setState(() => _future = context.read<AdminRepository>().languages());

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      showSnack(context, done);
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _edit([Language? l]) async {
    final values = await _textDialog(context,
        title: l == null ? 'Add language' : 'Edit language',
        labels: const ['Code (e.g. pag)', 'Name'],
        initial: l == null ? null : [l.code, l.name]);
    if (values == null || values[0].trim().isEmpty || values[1].trim().isEmpty || !mounted) return;
    await _run(() => context.read<AdminRepository>().saveLanguage(id: l?.id, code: values[0], name: values[1]), 'Language saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Languages')),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: FutureBuilder<List<Language>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _reload);
          return ListView(
            children: (snapshot.data ?? [])
                .map((l) => ListTile(
                      leading: CircleAvatar(child: Text(l.code.toUpperCase(), style: const TextStyle(fontSize: 12))),
                      title: Text(l.name),
                      onTap: () => _edit(l),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await confirmDialog(context, title: 'Delete language?', message: l.name, confirmLabel: 'Delete');
                          if (ok && context.mounted) {
                            await _run(() => context.read<AdminRepository>().deleteLanguage(l.id), 'Language deleted.');
                          }
                        },
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- Users

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  final _search = TextEditingController();
  List<AdminUser> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<AdminRepository>().users(search: _search.text.trim());
      _users = page.items;
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(AdminUser u, bool active) async {
    try {
      await context.read<AdminRepository>().setUserActive(u.id, active);
      if (!mounted) return;
      showSnack(context, active ? '${u.username} reactivated.' : '${u.username} deactivated and logged out.');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: const InputDecoration(hintText: 'Search username or email', prefixIcon: Icon(Icons.search), isDense: true),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : ListView(
                        children: _users
                            .map((u) => ListTile(
                                  title: Text(u.username),
                                  subtitle: Text('${u.role} · ${u.status}${u.schoolName != null ? ' · ${u.schoolName}' : ''}\n${u.email}'),
                                  isThreeLine: true,
                                  trailing: Switch(value: u.isActive, onChanged: (v) => _toggle(u, v)),
                                ))
                            .toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
