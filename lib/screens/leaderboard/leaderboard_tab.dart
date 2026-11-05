import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/leaderboard.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';

/// Weekly ranking of verified students from the same school (usernames only).
class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaderboardProvider>();
    final board = provider.board;

    if (provider.loading && board == null) return const LoadingView();
    if (provider.error != null && board == null) {
      return ErrorView(message: provider.error!, onRetry: provider.load);
    }
    if (board == null) return const SizedBox.shrink();

    final top = board.entries.take(3).toList();
    final rest = board.entries.skip(3).toList();

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeader(
            title: 'Leaderboard',
            subtitle: board.school,
            bottomPadding: 0,
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Pill(label: 'This week · ${_short(board.weekStart)} – ${_short(board.weekEnd)}', background: Colors.white24, foreground: Colors.white),
                    Pill(
                      label: board.myRank == null ? 'Solve a puzzle to join!' : 'You: #${board.myRank} of ${board.totalPlayers} · ${board.myPoints} pts',
                      background: AppColors.gold,
                      foreground: AppColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (top.isNotEmpty) _Podium(top: top) else const SizedBox(height: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                if (board.entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No points yet this week. Be the first!', textAlign: TextAlign.center),
                  ),
                ...rest.map((e) => _Row(entry: e)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.navySoft, borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.navy, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Only usernames of verified students from your school are shown.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF2A2F4A))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "2026-10-26" -> "Oct 26"
  static String _short(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

/// Top three: 2nd · 1st · 3rd, with bars of different heights.
class _Podium extends StatelessWidget {
  const _Podium({required this.top});

  final List<LeaderboardEntry> top;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? at(int i) => i < top.length ? top[i] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _Step(entry: at(1), height: 70, color: const Color(0xFFD9DCE8), avatar: 52)),
        const SizedBox(width: 10),
        Expanded(child: _Step(entry: at(0), height: 96, color: AppColors.gold, avatar: 64)),
        const SizedBox(width: 10),
        Expanded(child: _Step(entry: at(2), height: 54, color: const Color(0xFFE3A877), avatar: 48)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.entry, required this.height, required this.color, required this.avatar});

  final LeaderboardEntry? entry;
  final double height;
  final Color color;
  final double avatar;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatar,
          height: avatar,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: e.isMe ? AppColors.gold : Colors.white, width: 3),
          ),
          child: Text(e.username.isNotEmpty ? e.username[0].toUpperCase() : '?', style: displayStyle(size: avatar / 2.4, color: AppColors.ink)),
        ),
        const SizedBox(height: 6),
        Text(
          e.isMe ? '${e.username} (you)' : e.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            children: [
              Text('${e.rank}', style: displayStyle(size: 26, color: color)),
              Text('${e.points} pts', style: const TextStyle(color: Color(0xFFC9CDF2), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: e.isMe ? AppColors.goldSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: e.isMe ? AppColors.gold : AppColors.line, width: e.isMe ? 2 : 1),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('${e.rank}', textAlign: TextAlign.center, style: displayStyle(size: 18, color: AppColors.muted))),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.navySoft,
            child: Text(e.username.isNotEmpty ? e.username[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.isMe ? '${e.username} (you)' : e.username, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('${e.solved} solved', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Text('${e.points}', style: displayStyle(size: 18)),
        ],
      ),
    );
  }
}
