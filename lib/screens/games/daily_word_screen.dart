import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/guess_result.dart';
import '../../providers/game_provider.dart';
import '../../repositories/puzzle_repository.dart';
import '../../widgets/error_view.dart';
import '../../widgets/letter_tile.dart';
import '../../widgets/puzzle_card.dart';
import '../../widgets/result_sheet.dart';
import '../../widgets/word_keyboard.dart';

/// Daily Word Guess: letter tiles + keyboard. Colors come from the server.
class DailyWordScreen extends StatelessWidget {
  const DailyWordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(context.read<PuzzleRepository>())..loadDaily(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Daily Word Guess')),
        body: const SafeArea(child: _DailyBody()),
      ),
    );
  }
}

class _DailyBody extends StatefulWidget {
  const _DailyBody();

  @override
  State<_DailyBody> createState() => _DailyBodyState();
}

class _DailyBodyState extends State<_DailyBody> {
  String _typed = '';

  Future<void> _enter(GameProvider game) async {
    final length = game.puzzle?.answerLength ?? 5;
    if (_typed.length != length) {
      showSnack(context, 'Use all $length letters.');
      return;
    }
    final result = await game.submit(_typed);
    if (!mounted || result == null) return;
    setState(() => _typed = '');
    if (result.finished) showResultSheet(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final puzzle = game.puzzle;

    if (game.state == GameState.loading) return const LoadingView();
    if (game.state == GameState.failed || puzzle == null) {
      return ErrorView(message: game.error ?? 'Could not load the puzzle.', onRetry: game.loadDaily, icon: Icons.event_busy);
    }

    final length = puzzle.answerLength ?? 5;
    final playing = game.state == GameState.playing;
    // Tries used before this visit (no letters saved) are shown as gray rows.
    final previousTries = puzzle.myAttempt.triesUsed;
    final tileSize = ((MediaQuery.of(context).size.width - 48) / length).clamp(36.0, 58.0) - 6;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              Text(puzzle.prompt, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              if (puzzle.hint != null) ...[
                const SizedBox(height: 4),
                Text('Hint: ${puzzle.hint}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                if (puzzle.language != null) InfoChip(label: puzzle.language!.name),
                DifficultyChip(difficulty: puzzle.difficulty, points: puzzle.basePoints),
              ]),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(puzzle.maxTries, (row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(length, (col) => _tile(game, row, col, previousTries, tileSize)),
                  );
                }),
              ),
            ),
          ),
        ),
        if (game.message != null && playing)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(game.message!, style: TextStyle(color: Colors.grey.shade800)),
          ),
        if (game.state == GameState.finished)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              game.solved
                  ? 'Solved! Come back tomorrow for a new word.'
                  : 'The word was ${game.answer?.toUpperCase() ?? '—'}. Try again tomorrow!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: WordKeyboard(
            enabled: playing,
            keyStates: game.keyStates,
            onLetter: (l) {
              if (_typed.length < length) setState(() => _typed += l);
            },
            onBackspace: () {
              if (_typed.isNotEmpty) setState(() => _typed = _typed.substring(0, _typed.length - 1));
            },
            onEnter: () => _enter(game),
          ),
        ),
        if (game.state == GameState.submitting) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _tile(GameProvider game, int row, int col, int previousTries, double size) {
    // Rows 0..previousTries-1: earlier visit (unknown letters, gray).
    if (row < previousTries) return LetterTile(letter: '', state: 'absent', size: size);

    final boardRow = row - previousTries;
    if (boardRow < game.rows.length) {
      final List<LetterFeedback> letters = game.rows[boardRow];
      final cell = col < letters.length ? letters[col] : null;
      return LetterTile(letter: cell?.letter ?? '', state: cell?.state, size: size);
    }

    // The row being typed.
    if (boardRow == game.rows.length && game.state != GameState.finished) {
      final letter = col < _typed.length ? _typed[col] : '';
      return LetterTile(letter: letter, size: size);
    }

    return LetterTile(letter: '', size: size);
  }
}
