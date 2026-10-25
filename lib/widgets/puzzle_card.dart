import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/puzzle.dart';

/// A puzzle in a list: prompt preview, language, difficulty and status.
class PuzzleCard extends StatelessWidget {
  const PuzzleCard({super.key, required this.puzzle, required this.onTap});

  final Puzzle puzzle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attempt = puzzle.myAttempt;
    final IconData icon;
    final Color iconColor;
    if (attempt.solved) {
      icon = Icons.check_circle;
      iconColor = AppColors.correct;
    } else if (attempt.finished) {
      icon = Icons.cancel;
      iconColor = Colors.red.shade400;
    } else if (attempt.triesUsed > 0) {
      icon = Icons.timelapse;
      iconColor = AppColors.present;
    } else {
      icon = Icons.play_circle_fill;
      iconColor = AppColors.navy;
    }

    final preview = puzzle.type == PuzzleType.scramble ? puzzle.prompt.split('').join(' ') : puzzle.prompt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (puzzle.language != null) InfoChip(label: puzzle.language!.name),
              DifficultyChip(difficulty: puzzle.difficulty, points: puzzle.basePoints),
              if (attempt.solved) InfoChip(label: '+${attempt.points} pts', color: AppColors.correct),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.color = AppColors.navyLight});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class DifficultyChip extends StatelessWidget {
  const DifficultyChip({super.key, required this.difficulty, this.points});

  final String difficulty;
  final int? points;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      'easy' => AppColors.correct,
      'medium' => const Color(0xFFEF6C00),
      _ => Colors.red.shade700,
    };
    final label = '${difficulty[0].toUpperCase()}${difficulty.substring(1)}${points != null ? ' · $points pts' : ''}';
    return InfoChip(label: label, color: color);
  }
}
