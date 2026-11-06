import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../providers/puzzle_list_provider.dart';
import '../../repositories/puzzle_repository.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';
import '../../widgets/game_style.dart';
import '../../widgets/kwago.dart';
import '../../widgets/puzzle_card.dart';
import 'puzzle_screen.dart';

/// Bugtong / Word Scramble / Translate It list with a language picker
/// in the header and a difficulty bar below it.
class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key, required this.type});

  final String type;

  static String subtitleFor(String type) => switch (type) {
        PuzzleType.bugtong => 'Traditional riddles',
        PuzzleType.scramble => 'Fix the mixed-up letters',
        PuzzleType.translate => 'English · Filipino · Pangasinan',
        PuzzleType.salawikain => 'Buuin ang salawikain',
        PuzzleType.sawikain => 'Alamin ang kahulugan',
        PuzzleType.panitikan => 'Pabula, alamat, Ibong Adarna, Noli…',
        PuzzleType.context => 'Learn words from the sentence',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Starts at "All levels"; students pick a level with the chips.
      create: (context) => PuzzleListProvider(context.read<PuzzleRepository>(), type)..refresh(),
      child: Scaffold(backgroundColor: AppColors.night, body: _GameListBody(type: type)),
    );
  }
}

class _GameListBody extends StatelessWidget {
  const _GameListBody({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<PuzzleListProvider>();

    return Column(
      children: [
        AppHeader(
          title: PuzzleType.label(type),
          emoji: GameStyle.of(type).emoji,
          subtitle: GameListScreen.subtitleFor(type),
          showBack: true,
          bottomPadding: 18,
          child: PuzzleType.singleLanguage.contains(type)
              ? _LevelPicker(selected: list.level, onSelect: list.setLevel, onNavy: true)
              : _LanguagePicker(selected: list.language, onSelect: list.setLanguage),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: _DifficultyBar(selected: list.difficulty, onSelect: list.setDifficulty),
        ),

        Expanded(child: _content(context, list)),
      ],
    );
  }

  Widget _content(BuildContext context, PuzzleListProvider list) {
    if (list.loading && list.items.isEmpty) return const LoadingView();
    if (list.error != null && list.items.isEmpty) {
      return ErrorView(message: list.error!, onRetry: list.refresh, onNight: true);
    }
    if (list.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Kwago(message: 'Wala pang puzzle dito. Subukan ang ibang difficulty, wika o level!'),
        ),
      );
    }

    final solved = list.items.where((p) => p.myAttempt.solved).length;
    final total = list.items.length;

    return RefreshIndicator(
      onRefresh: list.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) list.loadMore();
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: list.items.length + 1 + (list.hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == 0) return _Progress(solved: solved, total: total, more: list.hasMore);
            final index = i - 1;
            if (index >= list.items.length) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
            }
            final puzzle = list.items[index];
            return PuzzleCard(
              puzzle: puzzle,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => PuzzleScreen(puzzleId: puzzle.id)));
                list.refresh(); // update solved / tries icons
              },
            );
          },
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.solved, required this.total, required this.more});

  final int solved;
  final int total;
  final bool more;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('★ $solved of $total${more ? '+' : ''} solved', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.onNight)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : solved / total,
                minHeight: 8,
                color: AppColors.gold,
                backgroundColor: AppColors.nightLine,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four big buttons in the navy header: All · EN · FIL · PAG.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  static const _options = <(String?, String, String)>[
    (null, 'All', 'languages'),
    ('en', 'EN', 'English'),
    ('fil', 'FIL', 'Filipino'),
    ('pag', 'PAG', 'Pangasinan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Choose a language', color: Color(0xFFC9CDF2)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (code, short, name) in _options)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _LanguageButton(
                    short: short,
                    name: name,
                    selected: selected == code,
                    onTap: () => onSelect(code),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.short, required this.name, required this.selected, required this.onTap});

  final String short;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(short, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: selected ? AppColors.ink : Colors.white)),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? AppColors.ink : const Color(0xFFC9CDF2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White segmented bar: Easy · Medium · Hard (always one selected).
class _DifficultyBar extends StatelessWidget {
  const _DifficultyBar({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  static const _options = <(String, String, Color)>[
    ('easy', 'Easy', Color(0xFF145C3B)),
    ('medium', 'Medium', Color(0xFF8A4A00)),
    ('hard', 'Hard', AppColors.wrong),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final (value, label, color) in _options)
            Expanded(
              child: Material(
                color: selected == value ? AppColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(value),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected == value ? Colors.white : color),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// School level chips: All · Gr 1–3 · Gr 4–6 · Gr 7–10 · Gr 11–12.
/// Students can try any level, not only their own grade.
/// Custom pills instead of ChoiceChip so unselected chips stay readable on navy.
class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.selected, required this.onSelect, this.onNavy = false});

  final String? selected;
  final ValueChanged<String?> onSelect;
  final bool onNavy; // drawn inside the navy header

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...SchoolLevel.all];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('School level', color: onNavy ? const Color(0xFFC9CDF2) : AppColors.muted),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final level in options)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _LevelPill(
                    label: level == null ? 'All levels' : SchoolLevel.shortLabel(level),
                    selected: selected == level,
                    onNavy: onNavy,
                    onTap: () => onSelect(level),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label, required this.selected, required this.onNavy, required this.onTap});

  final String label;
  final bool selected;
  final bool onNavy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? AppColors.gold
        : (onNavy ? Colors.white.withValues(alpha: 0.14) : Colors.white);
    final Color text = selected ? AppColors.ink : (onNavy ? Colors.white : AppColors.navy);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: StadiumBorder(side: onNavy || selected ? BorderSide.none : const BorderSide(color: AppColors.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: text)),
          ),
        ),
      ),
    );
  }
}
