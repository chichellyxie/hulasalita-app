import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../models/guess_result.dart';
import 'confetti.dart';
import 'kwago.dart';
import 'learn_card.dart';
import 'night_ui.dart';
import 'save_word_button.dart';

/// Shown when a puzzle ends: result, points, streak, new badges and the
/// learn card. Correct = mint + confetti, incorrect = soft rose.
Future<void> showResultSheet(BuildContext context, GuessResult result) {
  if (result.solved) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.lightImpact();
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Night.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => ResultSheet(result: result),
  );
}

class ResultSheet extends StatelessWidget {
  const ResultSheet({super.key, required this.result});

  final GuessResult result;

  static const _cheers = ['Galing mo! 🎉', 'Ang husay! Tama ka!', 'Wow, ang talino mo!', 'Tumpak! Tuloy lang!', 'Bravo! Isa pa?'];
  static const _comfort = ['Ayos lang! Matuto tayo sa sagot.', 'Muntik na! Basahin ang paliwanag.', 'Sa susunod, kaya mo yan!'];

  @override
  Widget build(BuildContext context) {
    final won = result.solved;
    final face = won ? Night.correct : Night.wrong;
    final deep = won ? Night.correctDeep : Night.wrongDeep;
    final rnd = Random(result.puzzleId);
    final kwagoLine = won ? _cheers[rnd.nextInt(_cheers.length)] : _comfort[rnd.nextInt(_comfort.length)];

    final sheet = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: Night.line, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: deep, shape: BoxShape.circle),
                      child: Icon(won ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(won ? 'Tama!' : 'Sayang!', style: displayStyle(size: 30, color: AppColors.ink)),
                          Text(
                            won ? 'Solved on try ${result.triesUsed} of ${result.maxTries}' : 'Out of tries — here is the answer.',
                            style: const TextStyle(color: Color(0xFF3A3F66), fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Text(won ? '🎉' : '📚', style: const TextStyle(fontSize: 34)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    NightPill('+${result.pointsEarned} pts', emoji: '⭐', color: AppColors.gold, textColor: AppColors.ink),
                    NightPill('${result.currentStreak}-day streak', emoji: '🔥', color: Colors.white.withValues(alpha: 0.7), textColor: AppColors.ink),
                    NightPill('${result.pointsToday}/${result.dailyCap} today', color: Colors.white.withValues(alpha: 0.7), textColor: AppColors.ink),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Kwago(message: kwagoLine, size: 52),
                  const SizedBox(height: 14),
                  if (won && result.dailyCapReached) ...[
                    Text(
                      'You reached the ${result.dailyCap}-point daily limit. Keep practicing — points come back tomorrow!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Night.textMuted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (result.newBadges.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold, width: 2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏅 New badge${result.newBadges.length > 1 ? 's' : ''}!', style: displayStyle(size: 17, color: const Color(0xFF6B4600))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: result.newBadges.map((b) => NightPill(b.name, emoji: '🏅', color: AppColors.gold, textColor: AppColors.ink)).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  LearnCardView(answer: result.answer, learn: result.learn, onNight: true),
                  const SizedBox(height: 12),
                  SaveWordButton(puzzleId: result.puzzleId, onNight: true),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GoldButton(label: won ? 'Continue' : 'Got it', icon: Icons.arrow_forward_rounded, onPressed: () => Navigator.pop(context)),
            ),
          ),
        ],
      ),
    );

    if (!won) return sheet;
    return Stack(
      children: [
        sheet,
        const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }
}
