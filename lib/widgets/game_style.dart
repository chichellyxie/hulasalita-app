import 'package:flutter/material.dart';

import '../models/puzzle.dart';

/// Emoji, pastel tile color and short subtitle for each game.
class GameStyle {
  const GameStyle(this.emoji, this.tile, this.subtitle);

  final String emoji;
  final Color tile; // pastel tile background (dark text on top)
  final String subtitle;

  static const _styles = <String, GameStyle>{
    PuzzleType.daily: GameStyle('🎯', Color(0xFFE6BC63), 'One new word every day'),
    PuzzleType.bugtong: GameStyle('🧩', Color(0xFFB2A6F4), 'Traditional riddles'),
    PuzzleType.scramble: GameStyle('🔀', Color(0xFFA6D3B3), 'Fix the letters'),
    PuzzleType.translate: GameStyle('🌏', Color(0xFF9FC6F4), 'EN · FIL · PAG'),
    PuzzleType.salawikain: GameStyle('📖', Color(0xFFE4A4B7), 'Finish the proverb'),
    PuzzleType.sawikain: GameStyle('💬', Color(0xFFEFBB8E), 'Idiom meanings'),
    PuzzleType.panitikan: GameStyle('🦜', Color(0xFFF8E0A0), 'Stories we read'),
    PuzzleType.context: GameStyle('🔎', Color(0xFFC8DB9D), 'Guess from the sentence'),
  };

  static GameStyle of(String type) => _styles[type] ?? const GameStyle('⭐', Color(0xFFDDE1F5), '');
}
