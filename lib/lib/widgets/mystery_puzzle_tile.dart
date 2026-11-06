import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// One row in the puzzle list. The question is HIDDEN until the student
/// opens it, so they pick by difficulty / language / level, not by content.
/// After a puzzle is solved, pass [solvedTitle] to let them review it.
class MysteryPuzzleTile extends StatelessWidget {
  final int number;            // 1, 2, 3 ...
  final String language;       // 'Filipino'
  final String difficulty;     // 'Easy' | 'Medium' | 'Hard'
  final String? level;         // 'Gr 4-6' (optional)
  final int points;            // 10
  final int tries;             // 4
  final bool solved;
  final String? solvedTitle;   // show the question only after solving
  final VoidCallback onTap;

  const MysteryPuzzleTile({
    super.key,
    required this.number,
    required this.language,
    required this.difficulty,
    required this.points,
    required this.tries,
    required this.onTap,
    this.level,
    this.solved = false,
    this.solvedTitle,
  });

  (Color, Color) get _diff => switch (difficulty) {
        'Easy' => AppPalette.easy,
        'Medium' => AppPalette.medium,
        _ => AppPalette.hard,
      };

  @override
  Widget build(BuildContext context) {
    final title = solved && solvedTitle != null
        ? solvedTitle!
        : 'Mystery puzzle #$number';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: solved
                        ? const LinearGradient(
                            colors: [AppPalette.ok, Color(0xFF7BE0B8)])
                        : AppPalette.headerGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: solved
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 28)
                      : const Text('?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppPalette.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _chip(language, AppPalette.tag),
                        _chip(difficulty, _diff),
                        if (level != null) _chip(level!, AppPalette.tag),
                      ]),
                      const SizedBox(height: 4),
                      Text('Up to $points pts · $tries tries',
                          style: const TextStyle(
                              color: AppPalette.mute,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppPalette.mute),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, (Color, Color) c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
            color: c.$1, borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: TextStyle(
                color: c.$2, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

/// Optional "Surprise me" button: opens a random unsolved puzzle.
class SurpriseButton extends StatelessWidget {
  final List<int> unsolvedIndexes; // indexes of unsolved puzzles in your list
  final void Function(int index) onPick;
  const SurpriseButton(
      {super.key, required this.unsolvedIndexes, required this.onPick});

  @override
  Widget build(BuildContext context) {
    if (unsolvedIndexes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.gold,
            foregroundColor: AppPalette.ink,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          onPressed: () => onPick(
              unsolvedIndexes[Random().nextInt(unsolvedIndexes.length)]),
          icon: const Icon(Icons.casino_rounded),
          label: const Text('Surprise me!'),
        ),
      ),
    );
  }
}
