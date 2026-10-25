import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulasalita_app/core/theme.dart';
import 'package:hulasalita_app/models/guess_result.dart';
import 'package:hulasalita_app/models/puzzle.dart';
import 'package:hulasalita_app/widgets/letter_tile.dart';

void main() {
  testWidgets('LetterTile shows the letter in upper case with the state color', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LetterTile(letter: 'a', state: 'correct')),
    ));

    expect(find.text('A'), findsOneWidget);
    expect(LetterTile.colorFor('correct'), AppColors.correct);
    expect(LetterTile.colorFor('present'), AppColors.present);
    expect(LetterTile.colorFor(null), AppColors.empty);
  });

  test('Puzzle JSON without an answer keeps answer null', () {
    final puzzle = Puzzle.fromJson({
      'id': 1,
      'type': 'daily',
      'difficulty': 'medium',
      'base_points': 20,
      'prompt': "Guess today's 5-letter Pangasinan word.",
      'max_tries': 6,
      'answer_length': 5,
      'my_attempt': {'tries_used': 0, 'tries_left': 6, 'solved': false, 'finished': false, 'points': 0},
    });

    expect(puzzle.answer, isNull);
    expect(puzzle.answerLength, 5);
    expect(puzzle.myAttempt.triesLeft, 6);
  });

  test('GuessResult parses letter feedback and badges', () {
    final result = GuessResult.fromJson({
      'puzzle_id': 1,
      'correct': true,
      'solved': true,
      'finished': true,
      'tries_used': 2,
      'tries_left': 4,
      'max_tries': 6,
      'points_earned': 16,
      'base_points': 20,
      'points_today': 16,
      'daily_cap': 150,
      'daily_cap_reached': false,
      'current_streak': 1,
      'letters': [
        {'letter': 'D', 'state': 'correct'},
      ],
      'answer': 'danum',
      'new_badges': [
        {'code': 'first_guess', 'name': 'Unang Hula', 'rule': 'puzzles_solved:1', 'earned': true, 'earned_at': null},
      ],
    });

    expect(result.pointsEarned, 16);
    expect(result.letters!.first.state, 'correct');
    expect(result.newBadges.first.description, 'Solve your first puzzle');
  });
}
