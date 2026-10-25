import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/leaderboard.dart';
import '../../providers/leaderboard_provider.dart';
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

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                Text(board.school ?? '', textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('This week: ${board.weekStart} to ${board.weekEnd}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Text(
                  board.myRank == null
                      ? 'Solve a puzzle to join this week\'s ranking!'
                      : 'Your rank: #${board.myRank} of ${board.totalPlayers} · ${board.myPoints} pts',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (board.entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No points yet this week. Be the first!', textAlign: TextAlign.center),
            ),
          ...board.entries.map((e) => _row(e)),
        ],
      ),
    );
  }

  Widget _row(LeaderboardEntry e) {
    final medal = switch (e.rank) {
      1 => const Color(0xFFFFC107),
      2 => const Color(0xFFB0BEC5),
      3 => const Color(0xFFBF8A5A),
      _ => null,
    };

    return Container(
      color: e.isMe ? const Color(0xFFE8EAF6) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medal ?? Colors.grey.shade200,
          child: Text('${e.rank}', style: TextStyle(fontWeight: FontWeight.bold, color: medal != null ? Colors.white : AppColors.navy)),
        ),
        title: Text(e.isMe ? '${e.username} (you)' : e.username,
            style: TextStyle(fontWeight: e.isMe ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text('${e.solved} solved'),
        trailing: Text('${e.points} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
