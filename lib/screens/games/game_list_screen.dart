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
import '../../widgets/night_ui.dart';
import 'puzzle_screen.dart';

/// A game's screen in two steps:
///  1. Setup: choose a grade level (learning games) or a language
///     (Bugtong, Word Scramble, Translate It), then Easy / Medium / Hard.
///  2. Mystery cards: the puzzles as numbered cards. The question stays
///     hidden until the student opens a card.
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
      create: (context) => PuzzleListProvider(context.read<PuzzleRepository>(), type)..refresh(),
      child: Scaffold(backgroundColor: Night.bg, body: _GameFlow(type: type)),
    );
  }
}

class _GameFlow extends StatefulWidget {
  const _GameFlow({required this.type});

  final String type;

  @override
  State<_GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<_GameFlow> {
  bool _showCards = false;

  bool get _leveled => PuzzleType.leveled.contains(widget.type);

  @override
  Widget build(BuildContext context) {
    final list = context.watch<PuzzleListProvider>();
    final style = GameStyle.of(widget.type);

    return PopScope(
      canPop: !_showCards,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showCards = false); // back = return to setup
      },
      child: Column(
        children: [
          AppHeader(
            title: PuzzleType.label(widget.type),
            emoji: style.emoji,
            subtitle: GameListScreen.subtitleFor(widget.type),
            showBack: true,
            onBack: _showCards ? () => setState(() => _showCards = false) : null,
            bottomPadding: _showCards ? 16 : 22,
            child: _showCards ? _SelectionBar(leveled: _leveled, onChange: () => setState(() => _showCards = false)) : null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              // Only the current view is drawn; the old one is removed at once,
              // so setup and cards never show on top of each other.
              layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
              child: _showCards
                  ? _CardsView(key: const ValueKey('cards'), type: widget.type)
                  : _SetupView(
                      key: const ValueKey('setup'),
                      type: widget.type,
                      leveled: _leveled,
                      list: list,
                      onStart: () => setState(() => _showCards = true),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Step 1: setup ─────────────────────────────

class _SetupView extends StatelessWidget {
  const _SetupView({super.key, required this.type, required this.leveled, required this.list, required this.onStart});

  final String type;
  final bool leveled;
  final PuzzleListProvider list;
  final VoidCallback onStart;

  static const _levels = <(String?, String, String, String)>[
    (null, 'All levels', '✨', 'Every grade'),
    (SchoolLevel.elemLower, 'Grades 1–3', '🌱', 'Elementary'),
    (SchoolLevel.elemUpper, 'Grades 4–6', '🌿', 'Elementary'),
    (SchoolLevel.jhs, 'Grades 7–10', '🌳', 'Junior High'),
    (SchoolLevel.shs, 'Grades 11–12', '🎓', 'Senior High'),
  ];

  static const _languages = <(String?, String, String, String)>[
    (null, 'All languages', '🌐', 'EN · FIL · PAG'),
    ('en', 'English', 'EN', 'English words'),
    ('fil', 'Filipino', 'FIL', 'Mga salitang Filipino'),
    ('pag', 'Pangasinan', 'PAG', 'Salitan Pangasinan'),
  ];

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.of(type);
    final options = leveled ? _levels : _languages;
    final selected = leveled ? list.level : list.language;
    final count = list.items.length;
    final countText = list.loading && list.items.isEmpty
        ? 'Looking for puzzles…'
        : count == 0
            ? 'No puzzles for this choice yet'
            : '$count${list.hasMore ? '+' : ''} puzzle${count == 1 ? '' : 's'} ready';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Kwago(message: leveled ? 'Pumili ng grade level at difficulty!' : 'Pumili ng wika at difficulty!', size: 54),
        const SizedBox(height: 20),
        NightLabel(leveled ? 'Step 1 · Grade level' : 'Step 1 · Language'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            for (final (code, name, mark, sub) in options)
              _ChoiceTile(
                mark: mark,
                title: name,
                subtitle: sub,
                selected: selected == code,
                accent: style.tile,
                onTap: () => leveled ? list.setLevel(code) : list.setLanguage(code),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const NightLabel('Step 2 · Difficulty'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (code, name, emoji, points, color) in Night.difficulties) ...[
              Expanded(
                child: _DifficultyTile(
                  emoji: emoji,
                  name: name,
                  points: points,
                  color: color,
                  selected: list.difficulty == code,
                  onTap: () => list.setDifficulty(code),
                ),
              ),
              if (code != 'hard') const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(countText, style: const TextStyle(color: Night.textMuted, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        GoldButton(
          label: 'Show puzzles',
          icon: Icons.style_rounded,
          busy: list.loading && list.items.isEmpty,
          onPressed: count == 0 ? null : onStart,
        ),
      ],
    );
  }
}

/// Level or language option: pastel when selected, dark card otherwise.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.mark, required this.title, required this.subtitle, required this.selected, required this.accent, required this.onTap});

  final String mark;
  final String title;
  final String subtitle;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.ink : Night.text;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? accent : Night.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.gold : Night.line, width: selected ? 2.5 : 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.75) : Night.cardDeep,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(mark,
                        style: mark.length > 2
                            ? TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: selected ? AppColors.ink : Night.text)
                            : const TextStyle(fontSize: 20, height: 1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: displayStyle(size: 15, color: fg)),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF3A3F66) : Night.textMuted)),
                      ],
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

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({required this.emoji, required this.name, required this.points, required this.color, required this.selected, required this.onTap});

  final String emoji;
  final String name;
  final int points;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 104,
          decoration: BoxDecoration(
            color: selected ? color : Night.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.gold : Night.line, width: selected ? 2.5 : 1),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 4))] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28, height: 1)),
                  const SizedBox(height: 6),
                  Text(name, style: displayStyle(size: 16, color: selected ? AppColors.ink : Night.text)),
                  Text('$points pts',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? const Color(0xFF3A3F66) : Night.textMuted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in the header on the cards step: the current choice + Change.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.leveled, required this.onChange});

  final bool leveled;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<PuzzleListProvider>();
    final (dName, dEmoji, _, dColor) = Night.difficulty(list.difficulty);
    final first = leveled
        ? (list.level == null ? 'All levels' : SchoolLevel.label(list.level!))
        : switch (list.language) { 'en' => 'English', 'fil' => 'Filipino', 'pag' => 'Pangasinan', _ => 'All languages' };
    return Row(
      children: [
        NightPill(first, color: Colors.white.withValues(alpha: 0.16), textColor: Colors.white),
        const SizedBox(width: 6),
        NightPill(dName, emoji: dEmoji, color: dColor, textColor: AppColors.ink),
        const Spacer(),
        TextButton.icon(
          onPressed: onChange,
          style: TextButton.styleFrom(foregroundColor: AppColors.gold, textStyle: const TextStyle(fontWeight: FontWeight.w800)),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Change'),
        ),
      ],
    );
  }
}

// ───────────────────────────── Step 2: mystery cards ─────────────────────────────

class _CardsView extends StatelessWidget {
  const _CardsView({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<PuzzleListProvider>();
    if (list.loading && list.items.isEmpty) return const LoadingView();
    if (list.error != null && list.items.isEmpty) {
      return ErrorView(message: list.error!, onRetry: list.refresh, onNight: true);
    }
    if (list.items.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(28), child: Kwago(message: 'Wala pang puzzle dito. Subukan ang ibang pili!')));
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('★ $solved of $total${list.hasMore ? '+' : ''} solved', style: const TextStyle(fontWeight: FontWeight.w800, color: Night.text)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : solved / total,
                              minHeight: 8,
                              color: AppColors.gold,
                              backgroundColor: Night.line,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Pick a card to reveal its question.', style: TextStyle(color: Night.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final puzzle = list.items[i];
                    return _MysteryCard(
                      number: i + 1,
                      puzzle: puzzle,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => PuzzleScreen(puzzleId: puzzle.id)));
                        list.refresh(); // update solved / tries
                      },
                    );
                  },
                  childCount: list.items.length,
                ),
              ),
            ),
            if (list.hasMore)
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.only(bottom: 24), child: Center(child: CircularProgressIndicator(color: AppColors.gold))),
              ),
          ],
        ),
      ),
    );
  }
}

/// A puzzle as a face-down card: number, difficulty and status only.
/// The question is revealed on the puzzle screen after the card is opened.
class _MysteryCard extends StatefulWidget {
  const _MysteryCard({required this.number, required this.puzzle, required this.onTap});

  final int number;
  final Puzzle puzzle;
  final VoidCallback onTap;

  @override
  State<_MysteryCard> createState() => _MysteryCardState();
}

class _MysteryCardState extends State<_MysteryCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final a = p.myAttempt;
    final style = GameStyle.of(p.type);
    final (dName, dEmoji, _, _) = Night.difficulty(p.difficulty);

    // Card face by status
    final (Color face, String badge, String status, IconData? statusIcon) = switch (a) {
      _ when a.solved => (Night.correct, '✓', 'Solved · +${a.points}', Icons.check_circle_rounded),
      _ when a.finished => (Night.wrong, '✕', 'Out of tries', Icons.cancel_rounded),
      _ when a.triesUsed > 0 => (style.tile, '?', '${a.triesLeft} tries left', Icons.timelapse_rounded),
      _ => (style.tile, '?', 'Up to ${p.basePoints} pts', null),
    };
    final open = a.finished; // solved or out of tries: can review

    return Semantics(
      button: true,
      label: 'Puzzle ${widget.number}, $dName, $status',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _whitePill('#${widget.number}'),
                    const Spacer(),
                    _whitePill('$dEmoji $dName'),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: open ? Colors.white.withValues(alpha: 0.7) : AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: displayStyle(size: 34, color: open ? (a.solved ? Night.correctDeep : Night.wrongDeep) : AppColors.gold),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (statusIcon != null) ...[Icon(statusIcon, size: 16, color: AppColors.ink), const SizedBox(width: 4)],
                    Expanded(
                      child: Text(status,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(open ? 'Tap to review' : 'Tap to reveal',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF3A3F66))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _whitePill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(999)),
        child: Text(t, style: displayStyle(size: 12.5, color: AppColors.ink)),
      );
}
