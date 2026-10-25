import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/badge.dart';
import '../../models/puzzle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/error_view.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatsProvider>();
    final user = context.watch<AuthProvider>().user;
    final stats = provider.stats;

    if (provider.loading && stats == null) return const LoadingView();
    if (provider.error != null && stats == null) return ErrorView(message: provider.error!, onRetry: provider.load);

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.navy,
                child: Text(
                  (user?.username.isNotEmpty ?? false) ? user!.username[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.username ?? '', style: Theme.of(context).textTheme.titleLarge),
                    Text(user?.school?.name ?? '', style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _statCard('${stats.totalPoints}', 'total points', Icons.star, AppColors.gold),
                _statCard('${stats.currentStreak}', 'day streak', Icons.local_fire_department, Colors.deepOrange),
                _statCard('${stats.pointsThisWeek}', 'points this week', Icons.date_range, AppColors.navyLight),
                _statCard('${stats.puzzlesSolved}', 'puzzles solved', Icons.check_circle, AppColors.correct),
              ],
            ),
            const SizedBox(height: 20),
            Text('Solved by game', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: PuzzleType.all
                    .map((t) => ListTile(
                          dense: true,
                          title: Text(PuzzleType.label(t)),
                          trailing: Text('${stats.solvedByType[t] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Badges (${stats.badgesEarned}/${stats.badges.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: stats.badges.map((b) => _badge(context, b)).toList(),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirmDialog(context, title: 'Log out?', message: 'You can log in again anytime.', confirmLabel: 'Log out');
              if (ok && context.mounted) await context.read<AuthProvider>().logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, GameBadge b) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showSnack(context, '${b.name}: ${b.description}${b.earned ? ' ✓' : ''}'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: b.earned ? AppColors.gold : Colors.grey.shade300,
            child: Icon(b.earned ? Icons.military_tech : Icons.lock_outline,
                color: b.earned ? Colors.white : Colors.grey.shade600, size: 30),
          ),
          const SizedBox(height: 6),
          Text(b.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: b.earned ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
