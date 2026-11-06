import 'dart:math';

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
import '../../widgets/night_ui.dart';
import '../../widgets/result_sheet.dart';
import '../../widgets/save_word_button.dart';

/// Bugtong, Translate It, the learning games (type or choose the answer)
/// and Word Scramble (tap the tiles), on the night theme.
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
            backgroundColor: Night.bg,
            body: Column(
              children: [
                AppHeader(
                  title: PuzzleType.label(p?.type ?? ''),
                  emoji: p == null ? null : GameStyle.of(p.type).emoji,
                  subtitle: subtitle,
                  showBack: true,
                  actions: [
                    if (p != null && game.state != GameState.finished)
                      NightPill('${game.triesLeft} ${game.triesLeft == 1 ? 'try' : 'tries'} left', color: AppColors.gold, textColor: AppColors.ink),
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

class _PuzzleBodyState extends State<_PuzzleBody> with SingleTickerProviderStateMixin {
  final _answer = TextEditingController();
  final List<int> _picked = []; // indexes of scramble letters, in tap order
  List<int>? _order; // display order of the scramble tray (for Shuffle)
  bool _showHint = false;
  String? _choice; // multiple choice: the option the student picked
  final Set<String> _wrongChoices = {}; // options already tried

  // Gentle shake of the question card after a wrong answer.
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _answer.dispose();
    _shake.dispose();
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
      _shake.forward(from: 0);
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
    final (dName, dEmoji, _, dColor) = Night.difficulty(puzzle.difficulty);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          NightPill(dName, emoji: dEmoji, color: dColor, textColor: AppColors.ink),
          NightPill('Up to +${puzzle.basePoints} pts', emoji: '⭐', color: AppColors.goldSoft, textColor: const Color(0xFF6B4600)),
          if (puzzle.level != null && PuzzleType.leveled.contains(puzzle.type)) NightPill(SchoolLevel.label(puzzle.level!)),
        ]),
        const SizedBox(height: 14),
        // The question "flips in" when the card is opened.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Opacity(opacity: ((v - 0.85) / 0.15).clamp(0.0, 1.0), child: Transform.scale(scale: v, child: child)),
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(offset: Offset(sin(_shake.value * pi * 6) * 10 * (1 - _shake.value), 0), child: child),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word Scramble: the clue is always visible above the letters.
                if (scramble && puzzle.hint != null) ...[
                  _clueCard(puzzle),
                  const SizedBox(height: 16),
                ],
                if (scramble) _scrambleBoard(puzzle, enabled: !finished && !busy) else _promptCard(puzzle),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (!scramble && puzzle.hint != null && !finished) _hintCard(puzzle.hint!),
        if (finished) ...[
          _finishedBanner(game, puzzle),
          const SizedBox(height: 12),
          LearnCardView(answer: game.answer, learn: game.learn, onNight: true),
          const SizedBox(height: 12),
          SaveWordButton(puzzleId: puzzle.id, onNight: true),
          const SizedBox(height: 10),
          NightOutlinedButton(label: 'Back to the cards', icon: Icons.style_rounded, onPressed: () => Navigator.pop(context)),
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
              cursorColor: AppColors.gold,
              style: displayStyle(size: 22, weight: FontWeight.w700, color: Colors.white),
              decoration: nightInput(
                puzzle.type == PuzzleType.translate ? 'Your answer in ${puzzle.language?.name ?? 'the language'}' : 'Your answer',
                icon: Icons.edit_rounded,
              ),
            ),
          if (game.message != null) ...[
            const SizedBox(height: 12),
            _tryAgainBanner(game.message!),
          ],
          const SizedBox(height: 16),
          GoldButton(
            label: scramble ? 'Check word' : (puzzle.isMultipleChoice ? 'Check answer' : 'Submit answer'),
            icon: Icons.check_rounded,
            busy: busy,
            onPressed: (puzzle.isMultipleChoice && _choice == null) ? null : () => _submit(game),
          ),
        ],
      ],
    );
  }

  /// Label above the question, per game.
  static String _promptLabel(String type) => switch (type) {
        PuzzleType.bugtong => 'Ano ito? What is it?',
        PuzzleType.salawikain => 'Buuin ang salawikain',
        PuzzleType.sawikain => 'Sawikain',
        PuzzleType.panitikan => 'Panitikan',
        PuzzleType.context => 'Context clues',
        _ => 'Find the word',
      };

  /// The question on the game's pastel color (same as its Home tile).
  Widget _promptCard(Puzzle puzzle) {
    final style = GameStyle.of(puzzle.type);
    final centered = puzzle.type == PuzzleType.translate;
    final long = puzzle.prompt.length > 45;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: style.tile,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10)),
                child: Text(style.emoji, style: const TextStyle(fontSize: 18, height: 1)),
              ),
              const SizedBox(width: 8),
              Text(_promptLabel(puzzle.type).toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: Color(0xFF3A3F66))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            puzzle.prompt,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: displayStyle(size: long ? 21 : (puzzle.type == PuzzleType.bugtong ? 26 : 28), weight: FontWeight.w700, color: AppColors.ink).copyWith(height: 1.3),
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
        const NightLabel('Choose the answer'),
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

  /// Word Scramble clue card (always shown).
  Widget _clueCard(Puzzle puzzle) {
    final style = GameStyle.of(puzzle.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.tile,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
            child: const Text('💡', style: TextStyle(fontSize: 26, height: 1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CLUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: Color(0xFF3A3F66))),
                const SizedBox(height: 2),
                Text(puzzle.hint!, style: displayStyle(size: 17, color: AppColors.ink, weight: FontWeight.w700)),
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
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22, height: 1)),
            const SizedBox(width: 10),
            Expanded(child: Text(hint, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3A2E0E)))),
          ],
        ),
      );
    }
    return NightOutlinedButton(label: 'Show hint', icon: Icons.lightbulb_outline_rounded, onPressed: () => setState(() => _showHint = true));
  }

  /// After a wrong answer: soft rose banner (not harsh red).
  Widget _tryAgainBanner(String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Night.wrong, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Night.wrongDeep, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink))),
            const Text('💪', style: TextStyle(fontSize: 20)),
          ],
        ),
      );

  Widget _finishedBanner(GameProvider game, Puzzle puzzle) {
    final solved = game.solved;
    final points = game.lastResult?.pointsEarned ?? puzzle.myAttempt.points;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: solved ? Night.correct : Night.wrong, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: solved ? Night.correctDeep : Night.wrongDeep, shape: BoxShape.circle),
            child: Icon(solved ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              solved ? 'Tama! You earned +$points points.' : 'Out of tries. Study the answer below!',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          Text(solved ? '🎉' : '📚', style: const TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  /// Word Scramble: answer slots, a letter tray, and Shuffle / Undo / Clear.
  Widget _scrambleBoard(Puzzle puzzle, {required bool enabled}) {
    final style = GameStyle.of(puzzle.type);
    final letters = puzzle.prompt.split('');
    final order = _order ??= List<int>.generate(letters.length, (i) => i);
    final length = puzzle.answerLength ?? letters.length;

    return Column(
      children: [
        const NightLabel('Build the word'),
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
        NightCard(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              const Text('Tap the letters in order', style: TextStyle(fontWeight: FontWeight.w700, color: Night.textMuted)),
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
                      color: style.tile,
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
            _toolButton('🔀', 'Shuffle', enabled ? () => setState(() => _order = [...order]..shuffle()) : null),
            const SizedBox(width: 10),
            _toolButton('↩️', 'Undo', (!enabled || _picked.isEmpty) ? null : () => setState(() => _picked.removeLast())),
            const SizedBox(width: 10),
            _toolButton('🧹', 'Clear', (!enabled || _picked.isEmpty) ? null : () => setState(() => _picked.clear())),
          ],
        ),
      ],
    );
  }

  Widget _toolButton(String emoji, String label, VoidCallback? onTap) => Expanded(
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Material(
            color: Night.card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Night.line)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
                    const SizedBox(height: 2),
                    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Night.text)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Answer slot: gold when filled, dashed-looking lavender outline when empty.
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
        color: filled ? AppColors.gold : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: filled ? AppColors.gold : Night.label.withValues(alpha: 0.6), width: 2),
        boxShadow: filled ? const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 4))] : null,
      ),
      child: Text(letter.toUpperCase(), style: displayStyle(size: 28, color: AppColors.ink)),
    );
  }
}

/// Letter in the tray, in the game's pastel color; faded outline once used.
class _TrayTile extends StatelessWidget {
  const _TrayTile({required this.letter, required this.used, required this.color, this.onTap});

  final String letter;
  final bool used;
  final Color color;
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
            color: used ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(16),
            border: used ? Border.all(color: Night.line, width: 2) : null,
            boxShadow: used ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 4))],
          ),
          child: Text(letter.toUpperCase(), style: displayStyle(size: 26, color: used ? Night.textMuted : AppColors.ink)),
        ),
      ),
    );
  }
}

/// One multiple-choice option on the night theme.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.letter, required this.text, required this.selected, required this.wrong, this.onTap});

  final String letter;
  final String text;
  final bool selected;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill = wrong ? Night.wrong : (selected ? const Color(0xFF34307A) : Night.card);
    final Color border = wrong ? Night.wrong : (selected ? AppColors.gold : Night.line);
    final Color textColor = wrong ? AppColors.ink : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: wrong ? '$text, already tried' : text,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: selected ? 2.5 : 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: wrong ? Night.wrongDeep : (selected ? AppColors.gold : Night.cardDeep),
                      shape: BoxShape.circle,
                    ),
                    child: wrong
                        ? const Icon(Icons.close_rounded, size: 18, color: Colors.white)
                        : Text(letter, style: displayStyle(size: 16, color: selected ? AppColors.ink : Night.text)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        decoration: wrong ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
