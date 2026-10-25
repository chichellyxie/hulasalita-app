import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/guess_result.dart';

/// Shown when a puzzle ends: points, streak, new badges, and the answer.
Future<void> showResultSheet(BuildContext context, GuessResult result) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ResultSheet(result: result),
  );
}

class ResultSheet extends StatelessWidget {
  const ResultSheet({super.key, required this.result});

  final GuessResult result;

  @override
  Widget build(BuildContext context) {
    final won = result.solved;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 64, color: won ? AppColors.gold : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(won ? 'Tama! Well done!' : 'Sayang! Out of tries.',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (result.answer != null) ...[
              const SizedBox(height: 8),
              Text('Answer: ${result.answer!.toUpperCase()}', style: theme.textTheme.titleMedium),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                _stat(context, '+${result.pointsEarned}', 'points'),
                _stat(context, '${result.currentStreak}🔥', 'day streak'),
                _stat(context, '${result.pointsToday}/${result.dailyCap}', 'today'),
              ],
            ),
            if (won && result.dailyCapReached) ...[
              const SizedBox(height: 12),
              Text(
                'You reached the ${result.dailyCap}-point daily limit. Keep practicing — points come back tomorrow!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            if (result.newBadges.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('New badge${result.newBadges.length > 1 ? 's' : ''}!', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: result.newBadges
                    .map((b) => Chip(avatar: const Icon(Icons.military_tech, color: AppColors.gold), label: Text(b.name)))
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.navy)),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
