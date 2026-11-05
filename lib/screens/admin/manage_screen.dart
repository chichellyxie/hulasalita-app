import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../models/language.dart';
import '../../models/school.dart';
import '../../repositories/admin_repository.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';

/// Entry point for schools, categories, languages and users.
class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const SectionLabel('Lists used across the app'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            _ManageTile(
              icon: Icons.school_rounded,
              title: 'Schools',
              subtitle: 'Schools in Urbiztondo students can choose',
              soft: AppColors.navySoft,
              color: AppColors.navy,
              onTap: () => open(const SchoolsAdminScreen()),
            ),
            _ManageTile(
              icon: Icons.sell_rounded,
              title: 'Categories',
              subtitle: 'Home, School, Food, Nature…',
              soft: const Color(0xFFFCEBC4),
              color: const Color(0xFF8A6100),
              onTap: () => open(const CategoriesAdminScreen()),
            ),
            _ManageTile(
              icon: Icons.translate_rounded,
              title: 'Languages',
              subtitle: 'English · Filipino · Pangasinan',
              soft: AppColors.translateSoft,
              color: AppColors.translate,
              onTap: () => open(const LanguagesAdminScreen()),
            ),
            _ManageTile(
              icon: Icons.people_alt_rounded,
              title: 'Users',
              subtitle: 'Search, deactivate or reactivate',
              soft: AppColors.bugtongSoft,
              color: AppColors.bugtong,
              onTap: () => open(const UsersAdminScreen()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(18)),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF8A6100)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Changes here appear in the app right away: new schools in the sign-up list, new categories and languages in the puzzle form.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF4A3A12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.soft,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color soft;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(title, style: displayStyle(size: 20, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ],
          ),
        ),
      ),
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
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('School type'),
        children: [
          for (final t in const ['elementary', 'secondary', 'integrated'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Row(
                children: [
                  Icon((s?.type ?? 'secondary') == t ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.navy),
                  const SizedBox(width: 12),
                  Expanded(child: Text(School.typeLabel(t))),
                ],
              ),
            ),
        ],
      ),
    );
    if (type == null || !mounted) return;
    await _run(
      () => context.read<AdminRepository>().saveSchool(id: s?.id, name: values[0], barangay: values[1], type: type, isActive: s?.isActive ?? true),
      'School saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: 'Schools', subtitle: 'Admin · Manage'),
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
                      subtitle: Text('${School.typeLabel(s.type)} · ${s.barangay ?? '—'} · ${s.usersCount ?? 0} users'),
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
                          () => context.read<AdminRepository>().saveSchool(id: s.id, name: s.name, barangay: s.barangay, type: s.type, isActive: v),
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
      appBar: const HeaderBar(title: 'Categories', subtitle: 'Admin · Manage'),
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
      appBar: const HeaderBar(title: 'Languages', subtitle: 'Admin · Manage'),
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
      appBar: const HeaderBar(title: 'Users', subtitle: 'Admin · Manage'),
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
