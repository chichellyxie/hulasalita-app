import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/guess_result.dart';
import 'app_header.dart';
import 'learn_card.dart';
import 'save_word_button.dart';

/// Shown when a puzzle ends: result, points, streak, new badges and the
/// Learn card (answer + teaching content).
Future<void> showResultSheet(BuildContext context, GuessResult result) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => ResultSheet(result: result),
  );
}

class ResultSheet extends StatelessWidget {
  const ResultSheet({super.key, required this.result});

  final GuessResult result;

  @override
  Widget build(BuildContext context) {
    final won = result.solved;
    final headerColor = won ? AppColors.correct : AppColors.navy;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(won ? Icons.check_rounded : Icons.sentiment_dissatisfied_rounded, color: headerColor, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(won ? 'Tama!' : 'Sayang!', style: displayStyle(size: 30, color: Colors.white)),
                          Text(
                            won
                                ? 'Solved on try ${result.triesUsed} of ${result.maxTries}'
                                : 'Out of tries — here is the answer.',
                            style: const TextStyle(color: Color(0xFFDDEFE5), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Pill(label: '+${result.pointsEarned} pts', background: AppColors.gold, foreground: AppColors.ink),
                    Pill(
                      label: '${result.currentStreak}-day streak',
                      icon: Icons.local_fire_department_rounded,
                      background: Colors.white24,
                      foreground: Colors.white,
                    ),
                    Pill(label: '${result.pointsToday}/${result.dailyCap} today', background: Colors.white24, foreground: Colors.white),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (won && result.dailyCapReached) ...[
                    Text(
                      'You reached the ${result.dailyCap}-point daily limit. Keep practicing — points come back tomorrow!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (result.newBadges.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel('New badge${result.newBadges.length > 1 ? 's' : ''}!', color: const Color(0xFF6B4600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: result.newBadges
                                .map((b) => Pill(label: b.name, icon: Icons.military_tech_rounded, background: AppColors.gold, foreground: AppColors.ink))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  LearnCardView(answer: result.answer, learn: result.learn),
                  const SizedBox(height: 12),
                  SaveWordButton(puzzleId: result.puzzleId),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
            ),
          ),
        ],
      ),
    );
  }
}
