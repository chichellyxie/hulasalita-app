import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/badge.dart';
import '../../models/puzzle.dart';
import '../../models/stats.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';
import '../../widgets/kwago.dart';
import '../../widgets/game_style.dart';
import '../../widgets/night_ui.dart';
import 'edit_profile_screen.dart';
import 'word_bank_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatsProvider>();
    final user = context.watch<AuthProvider>().user;
    final stats = provider.stats;
    final name = user?.username ?? '';

    if (provider.loading && stats == null) return const LoadingView();
    if (provider.error != null && stats == null) return ErrorView(message: provider.error!, onRetry: provider.load, onNight: true);

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeader(
            title: 'My Profile',
            actions: [
              HeaderButton(
                icon: Icons.edit_rounded,
                tooltip: 'Edit profile',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.gold,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: displayStyle(size: 30, color: AppColors.ink)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: displayStyle(size: 24, color: Colors.white)),
                      Text(user?.school?.name ?? '', style: const TextStyle(color: Color(0xFFC9CDF2), fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      const NightPill('Verified student', emoji: '✅', color: Night.correct, textColor: AppColors.ink),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stats != null) ...[
                  Kwago(
                    message: stats.badgesEarned == 0
                        ? 'Solve your first puzzle to earn a badge!'
                        : '${stats.badgesEarned} badges na! Ang galing mo, ${user?.username ?? ''}!',
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    _stat('${stats.totalPoints}', 'total points', '⭐', const Color(0xFFFFE08A)),
                    const SizedBox(width: 10),
                    _stat('${stats.currentStreak}', 'day streak', '🔥', const Color(0xFFFFC49B)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _stat('${stats.pointsThisWeek}', 'points this week', '📅', const Color(0xFFB9A8FF)),
                    const SizedBox(width: 10),
                    _stat('${stats.puzzlesSolved}', 'puzzles solved', '✅', const Color(0xFF9BE5C2)),
                  ]),
                  const SizedBox(height: 14),
                  _WordBankShortcut(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WordBankScreen()))),
                  const SizedBox(height: 14),
                  _solvedByGame(stats),
                  const SizedBox(height: 18),
                  _BadgesSection(stats: stats),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Night.wrong,
                    backgroundColor: Night.card,
                    side: const BorderSide(color: Night.line, width: 1.5),
                  ),
                  onPressed: () async {
                    final ok = await confirmDialog(context, title: 'Log out?', message: 'You can log in again anytime.', confirmLabel: 'Log out');
                    if (ok && context.mounted) await context.read<AuthProvider>().logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pastel stat tile, like the game tiles on Home.
  Widget _stat(String value, String label, String emoji, Color color) {
    return Expanded(
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(13)),
              child: Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: displayStyle(size: 24, color: AppColors.ink)),
                  Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF3A3F66))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _solvedByGame(PlayerStats stats) {
    final most = stats.solvedByType.values.fold<int>(1, (a, b) => b > a ? b : a);
    return NightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NightLabel('Solved by game'),
          for (final t in PuzzleType.all) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(GameStyle.of(t).emoji, style: const TextStyle(fontSize: 16, height: 1)),
                const SizedBox(width: 8),
                Expanded(child: Text(PuzzleType.label(t), style: const TextStyle(fontWeight: FontWeight.w700, color: Night.text))),
                Text('${stats.solvedByType[t] ?? 0}', style: displayStyle(size: 16, color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (stats.solvedByType[t] ?? 0) / most,
                minHeight: 8,
                color: GameStyle.of(t).tile,
                backgroundColor: Night.cardDeep,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Badges: shows 4 at first (earned ones, then the closest to being earned),
/// and the rest only when the student taps "Show all badges".
class _BadgesSection extends StatefulWidget {
  const _BadgesSection({required this.stats});

  final PlayerStats stats;

  @override
  State<_BadgesSection> createState() => _BadgesSectionState();
}

class _BadgesSectionState extends State<_BadgesSection> {
  static const _previewCount = 4;
  bool _expanded = false;

  /// Earned badges first, then locked ones by how close they are.
  List<GameBadge> _sorted() {
    final stats = widget.stats;
    double ratio(GameBadge b) => b.earned ? 2 : (b.goal == 0 ? 0 : b.progress(stats) / b.goal);
    return [...stats.badges]..sort((a, b) => ratio(b).compareTo(ratio(a)));
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final badges = _sorted();
    final hasMore = badges.length > _previewCount;
    final shown = _expanded ? badges : badges.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const NightLabel('Badges'),
            const Spacer(),
            Text('${stats.badgesEarned} of ${badges.length} earned',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.onNight, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: GridView.count(
            // Preview: one compact row of 4. Expanded: full tiles, 3 per row.
            crossAxisCount: _expanded ? 3 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: _expanded ? 0.72 : 0.68,
            children: shown.map((b) => _BadgeTile(badge: b, stats: stats, compact: !_expanded)).toList(),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.lavender),
            onPressed: () => setState(() => _expanded = !_expanded),
            iconAlignment: IconAlignment.end,
            icon: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
            label: Text(
              _expanded ? 'Show less' : 'Show all ${badges.length} badges',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

/// Earned badges are gold; locked badges show how to earn them and progress.
/// [compact] hides the rule text so 4 badges fit in one row.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.stats, this.compact = false});

  final GameBadge badge;
  final PlayerStats stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final b = badge;
    final progress = b.progress(stats);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      decoration: BoxDecoration(
        color: b.earned ? AppColors.goldSoft : Night.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.earned ? AppColors.gold : Night.line, width: b.earned ? 2 : 1),
      ),
      child: Column(
        children: [
          Container(
            width: compact ? 42 : 50,
            height: compact ? 42 : 50,
            decoration: BoxDecoration(
              color: b.earned ? AppColors.gold : Night.cardDeep,
              shape: BoxShape.circle,
              boxShadow: b.earned ? const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 3))] : null,
            ),
            child: Icon(b.earned ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                color: b.earned ? AppColors.ink : Night.textMuted, size: compact ? 22 : 26),
          ),
          const SizedBox(height: 6),
          Text(b.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800, height: 1.2, color: b.earned ? AppColors.ink : Night.text)),
          const SizedBox(height: 2),
          if (compact)
            const Spacer()
          else
            Expanded(
              child: Text(b.description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: b.earned ? const Color(0xFF6B5A2E) : Night.textMuted, height: 1.2)),
            ),
          if (b.earned)
            const Text('Earned', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF145C3B)))
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: b.goal == 0 ? 0 : progress / b.goal,
                minHeight: 5,
                color: AppColors.gold,
                backgroundColor: Night.cardDeep,
              ),
            ),
            const SizedBox(height: 3),
            Text('$progress/${b.goal}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Night.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// Navy card that opens the Word Bank.
class _WordBankShortcut extends StatelessWidget {
  const _WordBankShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Night.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppColors.gold, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Text('🔖', style: TextStyle(fontSize: 22, height: 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Word Bank', style: displayStyle(size: 18, color: Colors.white)),
                    const Text('Review the words you saved', style: TextStyle(color: Color(0xFFC9CDF2), fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
