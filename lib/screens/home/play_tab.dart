import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../games/daily_word_screen.dart';
import '../games/game_list_screen.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final stats = context.watch<StatsProvider>().stats;

    return RefreshIndicator(
      onRefresh: () => context.read<StatsProvider>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Kumusta, ${user?.username ?? ''}!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(icon: Icons.local_fire_department, color: Colors.deepOrange, value: '${stats?.currentStreak ?? 0}', label: 'day streak'),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.star,
                color: AppColors.gold,
                value: '${stats?.pointsToday ?? 0}/${stats?.dailyCap ?? 150}',
                label: 'points today',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _GameCard(
            title: PuzzleType.label(PuzzleType.daily),
            subtitle: 'One new word every day — the same for everyone.',
            icon: Icons.today,
            color: AppColors.navy,
            highlight: true,
            onTap: () => _open(context, const DailyWordScreen()),
          ),
          _GameCard(
            title: PuzzleType.label(PuzzleType.bugtong),
            subtitle: 'Solve traditional Filipino riddles.',
            icon: Icons.psychology_alt,
            color: const Color(0xFF6A1B9A),
            onTap: () => _open(context, const GameListScreen(type: PuzzleType.bugtong)),
          ),
          _GameCard(
            title: PuzzleType.label(PuzzleType.scramble),
            subtitle: 'Put the mixed-up letters in order.',
            icon: Icons.shuffle,
            color: const Color(0xFF00838F),
            onTap: () => _open(context, const GameListScreen(type: PuzzleType.scramble)),
          ),
          _GameCard(
            title: PuzzleType.label(PuzzleType.translate),
            subtitle: 'English · Filipino · Pangasinan.',
            icon: Icons.translate,
            color: const Color(0xFF2E7D32),
            onTap: () => _open(context, const GameListScreen(type: PuzzleType.translate)),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ],
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
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textColor = highlight ? Colors.white : null;
    return Card(
      color: highlight ? color : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: highlight ? Colors.white : color,
                child: Icon(icon, color: highlight ? color : Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: highlight ? Colors.white70 : Colors.grey.shade700)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
