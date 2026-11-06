import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/guess_result.dart';
import '../../providers/game_provider.dart';
import '../../repositories/puzzle_repository.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';
import '../../widgets/letter_tile.dart';
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
        backgroundColor: AppColors.night,
        body: Column(
          children: [
            Consumer<GameProvider>(
              builder: (context, game, _) => AppHeader(
                title: 'Daily Word Guess',
                emoji: '🎯',
                subtitle: 'Same word for everyone · new word every day',
                showBack: true,
                actions: [
                  if (game.puzzle != null && game.state != GameState.finished)
                    Pill(
                      label: '${game.triesLeft} ${game.triesLeft == 1 ? 'try' : 'tries'} left',
                      background: AppColors.gold,
                      foreground: AppColors.ink,
                    ),
                ],
              ),
            ),
            const Expanded(child: SafeArea(top: false, child: _DailyBody())),
          ],
        ),
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
      return ErrorView(message: game.error ?? 'Could not load the puzzle.', onRetry: game.loadDaily, icon: Icons.event_busy, onNight: true);
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
              Text(puzzle.prompt, textAlign: TextAlign.center, style: displayStyle(size: 18, color: Colors.white, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              _DailyHint(hint: game.hint, playing: playing, triesLeft: game.triesLeft),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                if (puzzle.language != null) Pill(label: puzzle.language!.name),
                Pill.difficulty(puzzle.difficulty, points: puzzle.basePoints),
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
        const _Legend(),
        const SizedBox(height: 6),
        if (game.message != null && playing)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(game.message!, style: const TextStyle(color: AppColors.onNight, fontWeight: FontWeight.w700)),
          ),
        if (game.state == GameState.finished)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              game.solved
                  ? 'Solved! Come back tomorrow for a new word.'
                  : 'The word was ${game.answer?.toUpperCase() ?? '—'}. Try again tomorrow!',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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

/// Explains the tile colors under the board.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onNightMuted)),
          ],
        );
    return Wrap(
      spacing: 14,
      alignment: WrapAlignment.center,
      children: [
        item(AppColors.correct, 'right spot'),
        item(AppColors.present, 'wrong spot'),
        item(AppColors.absent, 'not in word'),
      ],
    );
  }
}

/// Daily hint: locked until only 2 tries are left, then shown in gold.
class _DailyHint extends StatelessWidget {
  const _DailyHint({required this.hint, required this.playing, required this.triesLeft});

  final String? hint;
  final bool playing;
  final int triesLeft;

  @override
  Widget build(BuildContext context) {
    final unlocked = hint != null;
    if (!unlocked && !playing) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.goldSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? AppColors.gold : AppColors.line, width: unlocked ? 2 : 1),
      ),
      child: Row(
        children: [
          Icon(unlocked ? Icons.lightbulb_rounded : Icons.lock_outline_rounded,
              color: unlocked ? const Color(0xFF8A6100) : AppColors.muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              unlocked
                  ? 'Hint: $hint'
                  : 'A hint unlocks when you have 2 tries left (${triesLeft - 2} more ${triesLeft - 2 == 1 ? 'guess' : 'guesses'}).',
              style: TextStyle(
                fontSize: 13,
                fontWeight: unlocked ? FontWeight.w800 : FontWeight.w600,
                color: unlocked ? const Color(0xFF3A2E0E) : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
