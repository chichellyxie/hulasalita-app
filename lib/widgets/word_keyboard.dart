import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'letter_tile.dart';

/// On-screen keyboard for the Daily Word Guess. Keys take the color of the
/// best result seen so far for that letter.
class WordKeyboard extends StatelessWidget {
  const WordKeyboard({
    super.key,
    required this.onLetter,
    required this.onBackspace,
    required this.onEnter,
    this.keyStates = const {},
    this.enabled = true,
  });

  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;
  final Map<String, String> keyStates;
  final bool enabled;

  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                if (i == 2) _action(icon: Icons.keyboard_return, label: 'ENTER', onTap: onEnter, flex: 3),
                for (final ch in _rows[i].split('')) _key(ch),
                if (i == 2) _action(icon: Icons.backspace_outlined, label: '', onTap: onBackspace, flex: 3),
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(String letter) {
    final state = keyStates[letter];
    final color = state == null ? Colors.grey.shade200 : LetterTile.colorFor(state);
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: enabled ? () => onLetter(letter) : null,
            child: SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: state == null ? AppColors.navy : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _action({required IconData icon, required String label, required VoidCallback onTap, required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 50,
              child: Center(
                child: label.isEmpty
                    ? Icon(icon, color: Colors.white, size: 20)
                    : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
