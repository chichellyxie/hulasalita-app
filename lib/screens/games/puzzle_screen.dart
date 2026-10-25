import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../providers/game_provider.dart';
import '../../repositories/puzzle_repository.dart';
import '../../widgets/error_view.dart';
import '../../widgets/letter_tile.dart';
import '../../widgets/puzzle_card.dart';
import '../../widgets/result_sheet.dart';

/// Bugtong, Translate It (type the answer) and Word Scramble (tap the tiles).
class PuzzleScreen extends StatelessWidget {
  const PuzzleScreen({super.key, required this.puzzleId});

  final int puzzleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(context.read<PuzzleRepository>())..loadPuzzle(puzzleId),
      child: Consumer<GameProvider>(
        builder: (context, game, _) => Scaffold(
          appBar: AppBar(title: Text(PuzzleType.label(game.puzzle?.type ?? ''))),
          body: SafeArea(child: _PuzzleBody(puzzleId: puzzleId)),
        ),
      ),
    );
  }
}

class _PuzzleBody extends StatefulWidget {
  const _PuzzleBody({required this.puzzleId});

  final int puzzleId;

  @override
  State<_PuzzleBody> createState() => _PuzzleBodyState();
}

class _PuzzleBodyState extends State<_PuzzleBody> {
  final _answer = TextEditingController();
  final List<int> _picked = []; // indexes of scramble tiles, in tap order
  bool _showHint = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  String _currentGuess(Puzzle puzzle) {
    if (puzzle.type == PuzzleType.scramble) {
      return _picked.map((i) => puzzle.prompt[i]).join();
    }
    return _answer.text;
  }

  Future<void> _submit(GameProvider game) async {
    final puzzle = game.puzzle!;
    final result = await game.submit(_currentGuess(puzzle));
    if (!mounted || result == null) return;

    if (result.finished) {
      FocusScope.of(context).unfocus();
      await showResultSheet(context, result);
    } else {
      setState(() {
        _answer.clear();
        _picked.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final puzzle = game.puzzle;

    if (game.state == GameState.loading) return const LoadingView();
    if (game.state == GameState.failed || puzzle == null) {
      return ErrorView(message: game.error ?? 'Could not load the puzzle.', onRetry: () => game.loadPuzzle(widget.puzzleId));
    }

    final finished = game.state == GameState.finished;
    final busy = game.state == GameState.submitting;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (puzzle.language != null) InfoChip(label: puzzle.language!.name),
          if (puzzle.category != null) InfoChip(label: puzzle.category!.name, color: Colors.blueGrey),
          DifficultyChip(difficulty: puzzle.difficulty, points: puzzle.basePoints),
        ]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: puzzle.type == PuzzleType.scramble
                ? _scrambleTiles(puzzle, enabled: !finished && !busy)
                : Text(
                    puzzle.prompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.4),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (puzzle.hint != null)
          Align(
            child: _showHint
                ? Text('💡 ${puzzle.hint}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800))
                : TextButton.icon(
                    onPressed: () => setState(() => _showHint = true),
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Show hint'),
                  ),
          ),
        const SizedBox(height: 12),
        Text(
          finished
              ? (game.solved ? 'Solved! +${game.lastResult?.pointsEarned ?? puzzle.myAttempt.points} points' : 'Out of tries')
              : 'Tries left: ${game.triesLeft} of ${puzzle.maxTries}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: finished ? (game.solved ? AppColors.correct : Colors.red.shade700) : AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        if (finished)
          Card(
            color: game.solved ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Answer: ${game.answer?.toUpperCase() ?? '—'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          )
        else ...[
          if (puzzle.type == PuzzleType.scramble)
            _scrambleAnswer(puzzle)
          else
            TextField(
              controller: _answer,
              enabled: !busy,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(game),
              decoration: const InputDecoration(labelText: 'Your answer', prefixIcon: Icon(Icons.edit)),
            ),
          if (game.message != null) ...[
            const SizedBox(height: 8),
            Text(game.message!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : () => _submit(game),
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Submit answer'),
          ),
        ],
      ],
    );
  }

  Widget _scrambleTiles(Puzzle puzzle, {required bool enabled}) {
    final letters = puzzle.prompt.split('');
    return Column(
      children: [
        Text('Tap the letters in the right order', style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(letters.length, (i) {
            final used = _picked.contains(i);
            return LetterTile(
              letter: letters[i],
              size: 44,
              selected: used,
              onTap: (!enabled || used) ? null : () => setState(() => _picked.add(i)),
            );
          }),
        ),
      ],
    );
  }

  Widget _scrambleAnswer(Puzzle puzzle) {
    final length = puzzle.answerLength ?? puzzle.prompt.length;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(length, (i) {
            final letter = i < _picked.length ? puzzle.prompt[_picked[i]] : '';
            return LetterTile(letter: letter, size: 40);
          }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _picked.isEmpty ? null : () => setState(() => _picked.removeLast()),
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('Undo'),
            ),
            TextButton.icon(
              onPressed: _picked.isEmpty ? null : () => setState(() => _picked.clear()),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }
}
