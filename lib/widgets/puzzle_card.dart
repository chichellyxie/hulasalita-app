import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/puzzle.dart';
import 'app_header.dart';

/// A puzzle in a list: status icon, prompt preview, difficulty and points.
class PuzzleCard extends StatelessWidget {
  const PuzzleCard({super.key, required this.puzzle, required this.onTap});

  final Puzzle puzzle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attempt = puzzle.myAttempt;
    final (IconData icon, Color fg, Color bg, String status) = switch (attempt) {
      _ when attempt.solved => (Icons.check_rounded, AppColors.correct, AppColors.correctSoft, 'Review answer'),
      _ when attempt.finished => (Icons.close_rounded, AppColors.wrong, AppColors.wrongSoft, 'See the answer'),
      _ when attempt.triesUsed > 0 => (Icons.timelapse_rounded, const Color(0xFF8A6100), const Color(0xFFFCEBC4), '${attempt.triesLeft} tries left'),
      _ => (Icons.play_arrow_rounded, AppColors.navy, AppColors.navySoft, 'Up to ${puzzle.basePoints} pts · ${puzzle.maxTries} tries'),
    };

    final scramble = puzzle.type == PuzzleType.scramble;
    final preview = scramble ? puzzle.prompt.split('').join(' ') : puzzle.prompt;

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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: fg, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: scramble
                            ? displayStyle(size: 18, color: AppColors.ink, weight: FontWeight.w700).copyWith(letterSpacing: 2)
                            : const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (puzzle.language != null) Pill(label: puzzle.language!.name),
                          Pill.difficulty(puzzle.difficulty),
                          if (puzzle.level != null && PuzzleType.leveled.contains(puzzle.type))
                            Pill(label: SchoolLevel.shortLabel(puzzle.level!), background: AppColors.background, foreground: AppColors.muted),
                          if (attempt.solved)
                            Pill(label: 'Earned +${attempt.points}', background: const Color(0xFFFCEBC4), foreground: const Color(0xFF6B4600)),
                          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: attempt.solved ? AppColors.correct : AppColors.muted)),
                        ],
                      ),
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

/// Outlined chip (still used by admin screens).
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
  Widget build(BuildContext context) => Pill.difficulty(difficulty, points: points);
}
