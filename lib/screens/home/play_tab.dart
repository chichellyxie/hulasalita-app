import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/app_header.dart';
import '../games/daily_word_screen.dart';
import '../games/game_list_screen.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final stats = context.watch<StatsProvider>().stats;
    final name = user?.username ?? '';
    final today = stats?.pointsToday ?? 0;
    final cap = stats?.dailyCap ?? 150;

    return RefreshIndicator(
      onRefresh: () => context.read<StatsProvider>().load(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeader(
            title: 'Kumusta, $name!',
            subtitle: 'Handa ka na bang maglaro?',
            actions: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.gold,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: displayStyle(size: 20, color: AppColors.ink)),
              ),
            ],
            child: Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 28),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${stats?.currentStreak ?? 0}', style: displayStyle(size: 22, color: Colors.white)),
                            const Text('day streak', style: TextStyle(color: Color(0xFFC9CDF2), fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderStat(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: '$today', style: displayStyle(size: 22, color: Colors.white)),
                          TextSpan(
                            text: ' / $cap pts today',
                            style: const TextStyle(color: Color(0xFFC9CDF2), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ])),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: cap == 0 ? 0 : (today / cap).clamp(0.0, 1.0),
                            minHeight: 6,
                            color: AppColors.gold,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DailyCard(onTap: () => _open(context, const DailyWordScreen())),
                const SizedBox(height: 18),
                const SectionLabel('Word games'),
                const SizedBox(height: 10),
                _GameCard(
                  title: PuzzleType.label(PuzzleType.bugtong),
                  subtitle: 'Traditional riddles · ${stats?.solvedByType[PuzzleType.bugtong] ?? 0} solved',
                  icon: Icons.help_outline_rounded,
                  color: AppColors.bugtong,
                  soft: AppColors.bugtongSoft,
                  onTap: () => _open(context, const GameListScreen(type: PuzzleType.bugtong)),
                ),
                _GameCard(
                  title: PuzzleType.label(PuzzleType.scramble),
                  subtitle: 'Fix the mixed-up letters · ${stats?.solvedByType[PuzzleType.scramble] ?? 0} solved',
                  icon: Icons.shuffle_rounded,
                  color: AppColors.scramble,
                  soft: AppColors.scrambleSoft,
                  onTap: () => _open(context, const GameListScreen(type: PuzzleType.scramble)),
                ),
                _GameCard(
                  title: PuzzleType.label(PuzzleType.translate),
                  subtitle: 'EN · FIL · PAG · ${stats?.solvedByType[PuzzleType.translate] ?? 0} solved',
                  icon: Icons.translate_rounded,
                  color: AppColors.translate,
                  soft: AppColors.translateSoft,
                  onTap: () => _open(context, const GameListScreen(type: PuzzleType.translate)),
                ),
                const SizedBox(height: 8),
                const SectionLabel('Karunungang-bayan at panitikan'),
                const SizedBox(height: 10),
                _GameCard(
                  title: PuzzleType.label(PuzzleType.salawikain),
                  subtitle: 'Buuin ang salawikain · ${stats?.solvedByType[PuzzleType.salawikain] ?? 0} solved',
                  icon: Icons.format_quote_rounded,
                  color: AppColors.salawikain,
                  soft: AppColors.salawikainSoft,
                  onTap: () => _open(context, const GameListScreen(type: PuzzleType.salawikain)),
                ),
                _GameCard(
                  title: PuzzleType.label(PuzzleType.sawikain),
                  subtitle: 'Balat-sibuyas? Alamin ang kahulugan · ${stats?.solvedByType[PuzzleType.sawikain] ?? 0} solved',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: AppColors.sawikain,
                  soft: AppColors.sawikainSoft,
                  onTap: () => _open(context, const GameListScreen(type: PuzzleType.sawikain)),
                ),
                _GameCard(
                  title: PuzzleType.label(PuzzleType.panitikan),
                  subtitle: 'Ibong Adarna, Florante, Noli… · ${stats?.solvedByType[PuzzleType.panitikan] ?? 0} solved',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.panitikan,
                  soft: AppColors.panitikanSoft,
                  onTap: () => _open(context, const GameListScreen(type: PuzzleType.panitikan)),
                ),
                const SizedBox(height: 8),
                const SectionLabel('English'),
                const SizedBox(height: 10),
                _GameCard(
                  title: PuzzleType.label(PuzzleType.context),
                  subtitle: 'Learn words from the sentence · ${stats?.solvedByType[PuzzleType.context] ?? 0} solved',
                  icon: Icons.search_rounded,
                  color: AppColors.context,
                  soft: AppColors.contextSoft,
                  onTap: () => _open(context, const GameListScreen(type: PuzzleType.context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (context.mounted) context.read<StatsProvider>().load();
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
        child: child,
      );
}

/// Big gold card for today's Daily Word Guess.
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SectionLabel("Today's puzzle", color: Color(0xFF4A3200)),
                    const Spacer(),
                    Pill(label: 'New word daily', background: AppColors.navy, foreground: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Daily Word Guess', style: displayStyle(size: 26, color: AppColors.ink)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        width: 34,
                        height: 36,
                        margin: const EdgeInsets.only(right: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(9)),
                        child: Text('?', style: displayStyle(size: 18, color: Colors.white)),
                      ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Same word for everyone today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4A3200))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: displayStyle(size: 19, color: AppColors.ink)),
                      Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
