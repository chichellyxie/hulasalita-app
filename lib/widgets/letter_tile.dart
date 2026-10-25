import 'package:flutter/material.dart';

import '../core/theme.dart';

/// One square letter tile. [state]: correct | present | absent | null (empty/typing)
class LetterTile extends StatelessWidget {
  const LetterTile({super.key, required this.letter, this.state, this.size = 52, this.onTap, this.selected = false});

  final String letter;
  final String? state;
  final double size;
  final VoidCallback? onTap;
  final bool selected;

  static Color colorFor(String? state) => switch (state) {
        'correct' => AppColors.correct,
        'present' => AppColors.present,
        'absent' => AppColors.absent,
        _ => AppColors.empty,
      };

  @override
  Widget build(BuildContext context) {
    final filled = state != null;
    final background = selected ? Colors.grey.shade300 : colorFor(state);
    final textColor = filled ? Colors.white : AppColors.navy;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? background : (letter.isEmpty ? Colors.grey.shade400 : AppColors.navy),
            width: 2,
          ),
        ),
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.grey.shade500 : textColor,
          ),
        ),
      ),
    );
  }
}
