import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/puzzle.dart';
import '../../providers/puzzle_list_provider.dart';
import '../../repositories/puzzle_repository.dart';
import '../../widgets/error_view.dart';
import '../../widgets/puzzle_card.dart';
import 'puzzle_screen.dart';

/// Bugtong / Word Scramble / Translate It list with language and difficulty filters.
class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PuzzleListProvider(context.read<PuzzleRepository>(), type)..refresh(),
      child: Scaffold(
        appBar: AppBar(title: Text(PuzzleType.label(type))),
        body: const _GameListBody(),
      ),
    );
  }
}

class _GameListBody extends StatelessWidget {
  const _GameListBody();

  @override
  Widget build(BuildContext context) {
    final list = context.watch<PuzzleListProvider>();

    return Column(
      children: [
        _Filters(list: list),
        Expanded(child: _content(context, list)),
      ],
    );
  }

  Widget _content(BuildContext context, PuzzleListProvider list) {
    if (list.loading && list.items.isEmpty) return const LoadingView();
    if (list.error != null && list.items.isEmpty) {
      return ErrorView(message: list.error!, onRetry: list.refresh);
    }
    if (list.items.isEmpty) {
      return const ErrorView(message: 'No puzzles here yet. Try another language or difficulty.', icon: Icons.search_off);
    }

    return RefreshIndicator(
      onRefresh: list.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) list.loadMore();
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: list.items.length + (list.hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= list.items.length) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
            }
            final puzzle = list.items[i];
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

class _Filters extends StatelessWidget {
  const _Filters({required this.list});

  final PuzzleListProvider list;

  static const _languages = {null: 'All', 'en': 'English', 'fil': 'Filipino', 'pag': 'Pangasinan'};
  static const _difficulties = {null: 'All', 'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _row(_languages, list.language, list.setLanguage),
            _row(_difficulties, list.difficulty, list.setDifficulty),
          ],
        ),
      ),
    );
  }

  Widget _row(Map<String?, String> options, String? selected, ValueChanged<String?> onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: options.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected == e.key,
                    onSelected: (_) => onSelect(e.key),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
