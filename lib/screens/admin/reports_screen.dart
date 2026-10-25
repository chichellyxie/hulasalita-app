import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../models/puzzle.dart';
import '../../repositories/admin_repository.dart';
import '../../widgets/error_view.dart';

/// Summarized numbers: totals, per school, per game type and language.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  AdminReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _report = await context.read<AdminRepository>().report();
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    if (_loading && r == null) return const LoadingView();
    if (_error != null && r == null) return ErrorView(message: _error!, onRetry: _load);
    if (r == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _total('${r.verifiedStudents}', 'verified students'),
              _total('${r.pendingVerifications}', 'IDs waiting'),
              _total('${r.players}', 'players'),
              _total('${r.attempts}', 'puzzles played'),
              _total('${r.solveRate}%', 'solve rate'),
              _total('${r.points}', 'points earned'),
            ],
          ),
          const SizedBox(height: 20),
          Text('By school', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: r.bySchool
                  .map((s) => ListTile(
                        title: Text(s.school),
                        subtitle: Text('${s.verifiedStudents} verified · ${s.players} players · ${s.attempts} played · ${s.solved} solved'),
                        trailing: Text('${s.points} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text('By game and language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: r.byType.isEmpty
                  ? [const ListTile(title: Text('No games played yet.'))]
                  : r.byType
                      .map((t) => ListTile(
                            title: Text('${PuzzleType.label(t.type)} · ${t.language.toUpperCase()}'),
                            subtitle: LinearProgressIndicator(value: t.solveRate / 100, minHeight: 6),
                            trailing: Text('${t.solved}/${t.attempts}'),
                          ))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _total(String value, String label) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
              Text(label, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      );
}
