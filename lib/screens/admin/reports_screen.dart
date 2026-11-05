import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../models/puzzle.dart';
import '../../repositories/admin_repository.dart';
import '../../widgets/app_header.dart';
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

  static const _gameColors = {
    PuzzleType.daily: Color(0xFFC98A12),
    PuzzleType.bugtong: AppColors.bugtong,
    PuzzleType.scramble: AppColors.scramble,
    PuzzleType.translate: AppColors.translate,
    PuzzleType.salawikain: AppColors.salawikain,
    PuzzleType.sawikain: AppColors.sawikain,
    PuzzleType.panitikan: AppColors.panitikan,
    PuzzleType.context: AppColors.context,
  };

  @override
  Widget build(BuildContext context) {
    final r = _report;
    if (_loading && r == null) return const LoadingView();
    if (_error != null && r == null) return ErrorView(message: _error!, onRetry: _load);
    if (r == null) return const SizedBox.shrink();

    // Lowest solve rate among game/language pairs with enough plays.
    final hardest = r.byType.where((t) => t.attempts >= 5).fold<TypeReport?>(
          null,
          (low, t) => (low == null || t.solveRate < low.solveRate) ? t : low,
        );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [
              _total('${r.verifiedStudents}', 'verified students', Icons.verified_user_rounded, AppColors.navySoft, AppColors.navy),
              _total('${r.pendingVerifications}', 'IDs waiting', Icons.hourglass_top_rounded, const Color(0xFFFCEBC4), const Color(0xFF8A6100)),
              _total('${r.players}', 'players', Icons.people_alt_rounded, AppColors.bugtongSoft, AppColors.bugtong),
              _total('${r.attempts}', 'puzzles played', Icons.sports_esports_rounded, AppColors.scrambleSoft, AppColors.scramble),
              _total('${r.solveRate.toStringAsFixed(0)}%', 'solve rate', Icons.check_circle_rounded, AppColors.correctSoft, AppColors.correct),
              _total('${r.points}', 'points earned', Icons.star_rounded, const Color(0xFFFCEBC4), const Color(0xFF8A6100)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('By school · points'),
                  if (r.bySchool.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No schools yet.')),
                  for (final sc in r.bySchool)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF0F6)))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sc.school, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                Text('${sc.verifiedStudents} verified · ${sc.players} players · ${sc.solved}/${sc.attempts} solved',
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Text('${sc.points}', style: displayStyle(size: 18)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Solve rate by game and language'),
                  if (r.byType.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No games played yet.')),
                  for (final t in r.byType) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${PuzzleType.label(t.type)} · ${t.language.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        Text('${t.solved}/${t.attempts} · ', style: const TextStyle(fontSize: 13, color: Color(0xFF3A4060))),
                        Text('${t.solveRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: (t.solveRate / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        color: _gameColors[t.type] ?? AppColors.navy,
                        backgroundColor: const Color(0xFFE8EAF4),
                      ),
                    ),
                  ],
                  if (hardest != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(14)),
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Insight: ', style: TextStyle(fontWeight: FontWeight.w800)),
                          TextSpan(
                            text: '${PuzzleType.label(hardest.type)} in ${hardest.language.toUpperCase()} has the lowest solve rate '
                                '(${hardest.solveRate.toStringAsFixed(0)}%). Consider adding easier puzzles and filling in their Learn cards.',
                          ),
                        ]),
                        style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF4A3A12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _total(String value, String label, IconData icon, Color soft, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: displayStyle(size: 22))),
              Text(label, maxLines: 2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, height: 1.15)),
            ],
          ),
        ),
      );
}
