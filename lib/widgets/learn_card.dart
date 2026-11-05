import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/puzzle.dart';
import 'app_header.dart';

/// "Learn" section shown after a puzzle is finished: the answer, why it is
/// the answer, the word in three languages, a glossary and a fun fact.
/// Parts the admin did not fill in are simply not shown.
class LearnCardView extends StatelessWidget {
  const LearnCardView({super.key, required this.answer, this.learn});

  final String? answer;
  final LearnCard? learn;

  static const _languageNames = {'en': 'English', 'fil': 'Filipino', 'pag': 'Pangasinan'};

  @override
  Widget build(BuildContext context) {
    final card = learn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _box(
          color: Colors.white,
          children: [
            const SectionLabel('The answer'),
            const SizedBox(height: 4),
            Text(answer ?? '—', style: displayStyle(size: 34)),
            if (card?.explanation != null) ...[
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Meaning: ', style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: card!.explanation),
                ]),
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ],
        ),
        if (card != null && card.translations.isNotEmpty) ...[
          const SizedBox(height: 10),
          _box(
            color: Colors.white,
            children: [
              const SectionLabel('In three languages'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final code in const ['en', 'fil', 'pag'])
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_languageNames[code]!.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
                            Text(card.translations[code] ?? '—',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
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
            color: Colors.white,
            children: [
              const SectionLabel('Word to know'),
              const SizedBox(height: 4),
              Text(card!.glossary!, style: const TextStyle(fontSize: 14, height: 1.45)),
            ],
          ),
        ],
        if (card?.funFact != null) ...[
          const SizedBox(height: 10),
          _box(
            color: AppColors.goldSoft,
            border: false,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF6B4600)),
                  SizedBox(width: 6),
                  SectionLabel('Did you know?', color: Color(0xFF6B4600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(card!.funFact!, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF3A2E0E))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _box({required Color color, required List<Widget> children, bool border = true}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: border ? Border.all(color: AppColors.line) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}
