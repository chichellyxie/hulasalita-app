import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/puzzle.dart';
import 'app_header.dart';
import 'night_ui.dart';

/// "Learn" section shown after a puzzle is finished: the answer, its meaning,
/// the word in three languages, a word to know and a fun fact.
/// Parts the admin did not fill in are simply not shown.
/// [onNight] draws it on the dark student theme.
class LearnCardView extends StatelessWidget {
  const LearnCardView({super.key, required this.answer, this.learn, this.onNight = false});

  final String? answer;
  final LearnCard? learn;
  final bool onNight;

  static const _languageNames = {'en': 'English', 'fil': 'Filipino', 'pag': 'Pangasinan'};

  @override
  Widget build(BuildContext context) {
    final card = learn;
    final text = onNight ? Night.text : AppColors.ink;
    final muted = onNight ? Night.textMuted : AppColors.muted;
    final strong = onNight ? AppColors.gold : AppColors.navy;
    Widget label(String t) => onNight ? NightLabel(t) : SectionLabel(t);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _box(
          children: [
            label('The answer'),
            const SizedBox(height: 4),
            Text(answer ?? '—', style: displayStyle(size: 34, color: strong)),
            if (card?.explanation != null) ...[
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Meaning: ', style: TextStyle(fontWeight: FontWeight.w800, color: text)),
                  TextSpan(text: card!.explanation),
                ]),
                style: TextStyle(fontSize: 15, height: 1.5, color: text),
              ),
            ],
          ],
        ),
        if (card != null && card.translations.isNotEmpty) ...[
          const SizedBox(height: 10),
          _box(
            children: [
              label('In three languages'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final code in const ['en', 'fil', 'pag'])
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: onNight ? Night.cardDeep : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_languageNames[code]!.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: muted)),
                            Text(card.translations[code] ?? '—',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onNight ? Colors.white : AppColors.navy)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
        if (card?.glossary != null) ...[
          const SizedBox(height: 10),
          _box(
            children: [
              label('Word to know'),
              const SizedBox(height: 4),
              Text(card!.glossary!, style: TextStyle(fontSize: 14, height: 1.45, color: text)),
            ],
          ),
        ],
        if (card?.funFact != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('📚', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    SectionLabel('Did you know?', color: Color(0xFF6B4600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(card!.funFact!, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF3A2E0E))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _box({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onNight ? Night.card : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: onNight ? Night.line : AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}
