import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../models/stats.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/game_style.dart';
import '../../widgets/kwago.dart';
import '../games/daily_word_screen.dart';
import '../games/game_list_screen.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  /// What Kwago says on the home screen, based on today's progress.
  static String kwagoSays(PlayerStats? s) {
    if (s == null) return 'Kumusta! Ako si Kwago. Hula tayo ng salita!';
    if (s.pointsToday >= s.dailyCap) return 'Ang galing! Naabot mo na ang ${s.dailyCap} pts ngayon. Practice lang, bukas ulit!';
    if (s.currentStreak >= 3) return '${s.currentStreak} araw na ang streak mo! Huwag itong putulin!';
    if (s.pointsToday == 0) return 'Kumusta! Ako si Kwago. Hula tayo ng salita!';
    return 'Tuloy lang! ${s.dailyCap - s.pointsToday} pts pa bago ang daily limit.';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final stats = context.watch<StatsProvider>().stats;
    final name = user?.username ?? '';
    final today = stats?.pointsToday ?? 0;
    final cap = stats?.dailyCap ?? 150;
    int solved(String t) => stats?.solvedByType[t] ?? 0;

    return RefreshIndicator(
      onRefresh: () => context.read<StatsProvider>().load(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeader(
            title: 'Kumusta, $name!',
            subtitle: 'Handa ka na bang maglaro?',
            actions: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 3)),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.gold,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: displayStyle(size: 20, color: AppColors.ink)),
                ),
              ),
            ],
            child: Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: '$today', style: displayStyle(size: 22, color: Colors.white)),
                          TextSpan(text: ' / $cap pts today', style: const TextStyle(color: Color(0xFFC9CDF2), fontSize: 12, fontWeight: FontWeight.w700)),
                        ])),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: cap == 0 ? 0 : (today / cap).clamp(0.0, 1.0)),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 7, color: AppColors.gold, backgroundColor: Colors.white24),
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Kwago(message: kwagoSays(stats)),
                const SizedBox(height: 18),
                _DailyCard(onTap: () => _open(context, const DailyWordScreen())),
                const SizedBox(height: 22),
                const SectionLabel('Word games', color: AppColors.lavender),
                const SizedBox(height: 10),
                _TileRow(left: _tile(context, PuzzleType.bugtong, solved), right: _tile(context, PuzzleType.scramble, solved)),
                _tile(context, PuzzleType.translate, solved, wide: true),
                const SizedBox(height: 14),
                const SectionLabel('Karunungang-bayan at panitikan', color: AppColors.lavender),
                const SizedBox(height: 10),
                _TileRow(left: _tile(context, PuzzleType.salawikain, solved), right: _tile(context, PuzzleType.sawikain, solved)),
                _tile(context, PuzzleType.panitikan, solved, wide: true),
                const SizedBox(height: 14),
                const SectionLabel('English', color: AppColors.lavender),
                const SizedBox(height: 10),
                _tile(context, PuzzleType.context, solved, wide: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String type, int Function(String) solved, {bool wide = false}) {
    return _GameTile(
      type: type,
      solved: solved(type),
      wide: wide,
      onTap: () => _open(context, GameListScreen(type: type)),
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
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: child,
      );
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: left), const SizedBox(width: 12), Expanded(child: right)],
      );
}

/// Pastel game tile: emoji in a white box, a ★ solved count, title and subtitle.
/// Presses down a little when tapped.
class _GameTile extends StatefulWidget {
  const _GameTile({required this.type, required this.solved, required this.onTap, this.wide = false});

  final String type;
  final int solved;
  final VoidCallback onTap;
  final bool wide;

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.of(widget.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '${PuzzleType.label(widget.type)}, ${widget.solved} solved',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? 0.96 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: 144,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: style.tile,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 4), blurRadius: 0)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14)),
                        child: Text(style.emoji, style: const TextStyle(fontSize: 28, height: 1)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(999)),
                        child: Text('★ ${widget.solved}', style: displayStyle(size: 13, color: AppColors.ink)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(PuzzleType.label(widget.type), style: displayStyle(size: 19, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(style.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF3A3F66))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big gold card for today's Daily Word Guess.
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Daily Word Guess',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: GameStyle.of(PuzzleType.daily).tile,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [BoxShadow(color: Color(0xFFB08A3A), offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel("Today's puzzle · new word daily", color: Color(0xFF4A3200)),
                    const SizedBox(height: 4),
                    Text('Daily Word Guess', style: displayStyle(size: 26, color: AppColors.ink)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Container(
                            width: 36,
                            height: 38,
                            margin: const EdgeInsets.only(right: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
                            child: Text('?', style: displayStyle(size: 18, color: Colors.white)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Text('🎯', style: TextStyle(fontSize: 46)),
            ],
          ),
        ),
      ),
    );
  }
}
