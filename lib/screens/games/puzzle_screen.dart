import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../providers/game_provider.dart';
import '../../repositories/puzzle_repository.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';
import '../../widgets/game_style.dart';
import '../../widgets/learn_card.dart';
import '../../widgets/result_sheet.dart';
import '../../widgets/save_word_button.dart';

/// Bugtong, Translate It (type the answer) and Word Scramble (tap the tiles).
class PuzzleScreen extends StatelessWidget {
  const PuzzleScreen({super.key, required this.puzzleId});

  final int puzzleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(context.read<PuzzleRepository>())..loadPuzzle(puzzleId),
      child: Consumer<GameProvider>(
        builder: (context, game, _) {
          final p = game.puzzle;
          final subtitle = p == null
              ? null
              : [if (p.language != null) p.language!.name, if (p.category != null) p.category!.name].join(' · ');
          return Scaffold(
            backgroundColor: AppColors.night,
            body: Column(
              children: [
                AppHeader(
                  title: PuzzleType.label(p?.type ?? ''),
                  emoji: p == null ? null : GameStyle.of(p.type).emoji,
                  subtitle: subtitle,
                  showBack: true,
                  actions: [
                    if (p != null && game.state != GameState.finished)
                      Pill(
                        label: '${game.triesLeft} ${game.triesLeft == 1 ? 'try' : 'tries'} left',
                        background: AppColors.gold,
                        foreground: AppColors.ink,
                      ),
                  ],
                ),
                Expanded(child: _PuzzleBody(puzzleId: puzzleId)),
              ],
            ),
          );
        },
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
  final List<int> _picked = []; // indexes of scramble letters, in tap order
  List<int>? _order; // display order of the scramble tray (for Shuffle)
  bool _showHint = false;
  String? _choice; // multiple choice: the option the student picked
  final Set<String> _wrongChoices = {}; // options already tried

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  String _currentGuess(Puzzle puzzle) {
    if (puzzle.type == PuzzleType.scramble) {
      return _picked.map((i) => puzzle.prompt[i]).join();
    }
    if (puzzle.isMultipleChoice) return _choice ?? '';
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
      HapticFeedback.lightImpact(); // wrong guess
      setState(() {
        _answer.clear();
        _picked.clear();
        if (_choice != null) _wrongChoices.add(_choice!);
        _choice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final puzzle = game.puzzle;

    if (game.state == GameState.loading) return const LoadingView();
    if (game.state == GameState.failed || puzzle == null) {
      return ErrorView(message: game.error ?? 'Could not load the puzzle.', onRetry: () => game.loadPuzzle(widget.puzzleId), onNight: true);
    }

    final finished = game.state == GameState.finished;
    final busy = game.state == GameState.submitting;
    final scramble = puzzle.type == PuzzleType.scramble;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          Pill.difficulty(puzzle.difficulty),
          Pill(label: 'Up to +${puzzle.basePoints} pts', background: const Color(0xFFFCEBC4), foreground: const Color(0xFF6B4600)),
        ]),
        const SizedBox(height: 14),
        // Word Scramble: the clue (hint) is always visible above the letters.
        if (scramble && puzzle.hint != null) ...[
          _clueCard(puzzle.hint!),
          const SizedBox(height: 16),
        ],
        if (scramble) _scrambleBoard(puzzle, enabled: !finished && !busy) else _promptCard(puzzle),
        const SizedBox(height: 14),
        if (!scramble && puzzle.hint != null && !finished) _hintCard(puzzle.hint!),
        if (finished) ...[
          _finishedBanner(game, puzzle),
          const SizedBox(height: 12),
          LearnCardView(answer: game.answer, learn: game.learn),
          const SizedBox(height: 12),
          SaveWordButton(puzzleId: puzzle.id),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: AppColors.lavender, width: 2)),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.list_rounded),
            label: const Text('Back to the list'),
          ),
        ] else ...[
          const SizedBox(height: 14),
          if (puzzle.isMultipleChoice)
            _choiceList(puzzle, enabled: !busy)
          else if (!scramble)
            TextField(
              controller: _answer,
              enabled: !busy,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(game),
              style: displayStyle(size: 22, weight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: puzzle.type == PuzzleType.translate ? 'Your answer in ${puzzle.language?.name ?? 'the language'}' : 'Your answer',
                prefixIcon: const Icon(Icons.edit_rounded),
              ),
            ),
          if (game.message != null) ...[
            const SizedBox(height: 10),
            Text(game.message!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF9C9C), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (busy || (puzzle.isMultipleChoice && _choice == null)) ? null : () => _submit(game),
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(scramble ? 'Check word' : (puzzle.isMultipleChoice ? 'Check answer' : 'Submit answer')),
          ),
        ],
      ],
    );
  }

  /// Label and icon above the prompt, per game.
  static (String, IconData) _promptLabel(String type) => switch (type) {
        PuzzleType.bugtong => ('Ano ito? What is it?', Icons.lightbulb_outline_rounded),
        PuzzleType.salawikain => ('Salawikain', Icons.format_quote_rounded),
        PuzzleType.sawikain => ('Sawikain', Icons.chat_bubble_outline_rounded),
        PuzzleType.panitikan => ('Panitikan', Icons.menu_book_rounded),
        PuzzleType.context => ('Context clues', Icons.search_rounded),
        _ => ('Find the word', Icons.translate_rounded),
      };

  /// Riddle / proverb / question, in a big white card.
  Widget _promptCard(Puzzle puzzle) {
    final centered = puzzle.type == PuzzleType.translate;
    final (label, icon) = _promptLabel(puzzle.type);
    final long = puzzle.prompt.length > 45;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x141B1F6B), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8A6100)),
              const SizedBox(width: 6),
              SectionLabel(label, color: const Color(0xFF8A6100)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            puzzle.prompt,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: displayStyle(size: long ? 21 : (puzzle.type == PuzzleType.bugtong ? 26 : 28), weight: FontWeight.w700).copyWith(height: 1.3),
          ),
        ],
      ),
    );
  }

  /// Multiple choice: one big button per option. Wrong options are crossed out.
  Widget _choiceList(Puzzle puzzle, {required bool enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Choose the answer', color: AppColors.lavender),
        const SizedBox(height: 8),
        for (final (i, option) in puzzle.choices.indexed) ...[
          _ChoiceButton(
            letter: String.fromCharCode(65 + i),
            text: option,
            selected: _choice == option,
            wrong: _wrongChoices.contains(option),
            onTap: (!enabled || _wrongChoices.contains(option)) ? null : () => setState(() => _choice = option),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// Word Scramble clue card (always shown, like the canvas design).
  Widget _clueCard(String clue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x141B1F6B), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: const Color(0xFFFCEBC4), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF8A6100), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Clue'),
                const SizedBox(height: 2),
                Text(clue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintCard(String hint) {
    if (_showHint) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFF8A6100)),
            const SizedBox(width: 10),
            Expanded(child: Text(hint, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3A2E0E)))),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => setState(() => _showHint = true),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: AppColors.lavender, width: 2)),
      icon: const Icon(Icons.lightbulb_outline_rounded),
      label: const Text('Show hint'),
    );
  }

  Widget _finishedBanner(GameProvider game, Puzzle puzzle) {
    final solved = game.solved;
    final points = game.lastResult?.pointsEarned ?? puzzle.myAttempt.points;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: solved ? AppColors.correctSoft : AppColors.wrongSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(solved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: solved ? AppColors.correct : AppColors.wrong),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              solved ? 'Tama! You earned +$points points.' : 'Out of tries. Study the answer below!',
              style: TextStyle(fontWeight: FontWeight.w800, color: solved ? const Color(0xFF145C3B) : AppColors.wrong),
            ),
          ),
        ],
      ),
    );
  }

  /// Word Scramble: answer slots, a gold letter tray, and Shuffle / Undo / Clear.
  Widget _scrambleBoard(Puzzle puzzle, {required bool enabled}) {
    final letters = puzzle.prompt.split('');
    final order = _order ??= List<int>.generate(letters.length, (i) => i);
    final length = puzzle.answerLength ?? letters.length;

    return Column(
      children: [
        const Text('Build the word', style: TextStyle(color: AppColors.onNightMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(length, (i) {
            final letter = i < _picked.length ? letters[_picked[i]] : '';
            return _Tile(letter: letter, filled: letter.isNotEmpty);
          }),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(color: AppColors.navySoft, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              const Text('Tap the letters in order', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3A4060))),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final i in order)
                    _TrayTile(
                      letter: letters[i],
                      used: _picked.contains(i),
                      onTap: (!enabled || _picked.contains(i)) ? null : () => setState(() => _picked.add(i)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _toolButton(Icons.shuffle_rounded, 'Shuffle', enabled ? () => setState(() => _order = [...order]..shuffle()) : null),
            const SizedBox(width: 10),
            _toolButton(Icons.backspace_outlined, 'Undo', (!enabled || _picked.isEmpty) ? null : () => setState(() => _picked.removeLast())),
            const SizedBox(width: 10),
            _toolButton(Icons.clear_all_rounded, 'Clear', (!enabled || _picked.isEmpty) ? null : () => setState(() => _picked.clear())),
          ],
        ),
      ],
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback? onTap) => Expanded(
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.line),
            backgroundColor: Colors.white,
            padding: EdgeInsets.zero,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 20), Text(label, style: const TextStyle(fontSize: 12))],
          ),
        ),
      );
}

/// Answer slot: navy when filled, dashed-looking outline when empty.
class _Tile extends StatelessWidget {
  const _Tile({required this.letter, required this.filled});

  final String letter;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 52,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: filled ? AppColors.navy : const Color(0xFF9FA6CC), width: 2),
      ),
      child: Text(letter.toUpperCase(), style: displayStyle(size: 28, color: Colors.white)),
    );
  }
}

/// Gold letter in the tray; faded outline once used.
class _TrayTile extends StatelessWidget {
  const _TrayTile({required this.letter, required this.used, this.onTap});

  final String letter;
  final bool used;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Letter $letter${used ? ', used' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 52,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: used ? Colors.transparent : AppColors.gold,
            borderRadius: BorderRadius.circular(16),
            border: used ? Border.all(color: const Color(0xFFC3C8E4), width: 2) : null,
            boxShadow: used ? null : const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 4))],
          ),
          child: Text(letter.toUpperCase(), style: displayStyle(size: 26, color: used ? const Color(0xFF9FA6CC) : AppColors.ink)),
        ),
      ),
    );
  }
}

/// One multiple-choice option: A/B/C/D badge + text.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.letter, required this.text, required this.selected, required this.wrong, this.onTap});

  final String letter;
  final String text;
  final bool selected;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = wrong ? AppColors.wrongSoft : (selected ? AppColors.navy : AppColors.line);
    final Color fill = wrong ? const Color(0xFFFCF4F4) : (selected ? AppColors.navySoft : Colors.white);
    return Semantics(
      button: true,
      selected: selected,
      label: wrong ? '$text, already tried' : text,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: wrong ? AppColors.wrongSoft : (selected ? AppColors.navy : AppColors.background),
                    shape: BoxShape.circle,
                  ),
                  child: wrong
                      ? const Icon(Icons.close_rounded, size: 18, color: AppColors.wrong)
                      : Text(letter, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.navy)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: wrong ? AppColors.muted : AppColors.ink,
                      decoration: wrong ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
