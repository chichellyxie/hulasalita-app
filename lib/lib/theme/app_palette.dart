import 'package:flutter/material.dart';

/// Refined version of your current navy + gold look:
/// same identity, but cleaner contrast and brighter, less muddy tiles.
class AppPalette {
  // Backgrounds
  static const bg = Color(0xFF16174A);        // deep indigo (screen background)
  static const bgSoft = Color(0xFF1F2160);    // nav bar, raised areas
  static const headerA = Color(0xFF2B2FB5);   // header gradient start
  static const headerB = Color(0xFF6A4BE8);   // header gradient end

  // Accents
  static const gold = Color(0xFFFFC83D);
  static const goldDark = Color(0xFFE0A21A);
  static const pink = Color(0xFFFF7EB6);

  // Cards and text
  static const card = Colors.white;
  static const cardTint = Color(0xFFF1EDFF);
  static const ink = Color(0xFF22204F);
  static const mute = Color(0xFF7A76A8);
  static const onDarkMute = Color(0xFFB9B6F0);

  // Feedback
  static const ok = Color(0xFF3DCB93);
  static const warn = Color(0xFFFFB347);
  static const bad = Color(0xFFFF6B8A);

  // Game tiles on the Home screen, in order:
  // Bugtong, Word Scramble, Translate It, Salawikain, Sawikain, Panitikan, Context Clues
  static const tiles = <Color>[
    Color(0xFFB9A8FF), // lavender
    Color(0xFF9BE5C2), // mint
    Color(0xFF9CCBFF), // sky
    Color(0xFFFFA8C5), // rose
    Color(0xFFFFC49B), // peach
    Color(0xFFFFE08A), // lemon
    Color(0xFFA6E3F2), // aqua
  ];

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerA, headerB],
  );

  // Difficulty chips: (background, text)
  static const easy = (Color(0xFFD8F7E8), Color(0xFF14805A));
  static const medium = (Color(0xFFFFEFC2), Color(0xFF9A6A00));
  static const hard = (Color(0xFFFFD9E2), Color(0xFFB8355A));
  static const tag = (Color(0xFFE6E1FF), Color(0xFF4B3FB8));
}
