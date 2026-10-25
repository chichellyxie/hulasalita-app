import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/admin_models.dart';
import '../../models/puzzle.dart';
import '../../repositories/admin_repository.dart';
import '../../widgets/error_view.dart';
import '../../widgets/puzzle_card.dart';
import 'puzzle_form_screen.dart';

class AdminPuzzlesScreen extends StatefulWidget {
  const AdminPuzzlesScreen({super.key});

  @override
  State<AdminPuzzlesScreen> createState() => _AdminPuzzlesScreenState();
}

class _AdminPuzzlesScreenState extends State<AdminPuzzlesScreen> {
  final List<AdminPuzzle> _items = [];
  String? _type;
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more && !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<AdminRepository>().puzzles(
            page: more ? _page + 1 : 1,
            type: _type,
            search: _search.text.trim(),
          );
      if (!more) _items.clear();
      _items.addAll(page.items);
      _page = page.currentPage;
      _hasMore = page.hasMore;
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm([AdminPuzzle? puzzle]) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PuzzleFormScreen(puzzle: puzzle)));
    if (saved == true) _load();
  }

  Future<void> _delete(AdminPuzzle p) async {
    final ok = await confirmDialog(context, title: 'Delete puzzle?', message: p.prompt, confirmLabel: 'Delete');
    if (!ok || !mounted) return;
    try {
      await context.read<AdminRepository>().deletePuzzle(p.id);
      if (!mounted) return;
      showSnack(context, 'Puzzle deleted.');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_puzzle',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New puzzle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search prompt or answer',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _search.clear();
                  _load();
                }),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [null, ...PuzzleType.all].map((t) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(t == null ? 'All' : PuzzleType.label(t)),
                    selected: _type == t,
                    onSelected: (_) {
                      setState(() => _type = t);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading && _items.isEmpty) return const LoadingView();
    if (_error != null && _items.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_items.isEmpty) return const ErrorView(message: 'No puzzles found.', icon: Icons.search_off);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton(onPressed: _loading ? null : () => _load(more: true), child: const Text('Load more')),
            );
          }
          final p = _items[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: ListTile(
              onTap: () => _openForm(p),
              title: Text(p.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 6, runSpacing: 4, children: [
                  InfoChip(label: PuzzleType.label(p.type)),
                  if (p.language != null) InfoChip(label: p.language!.code.toUpperCase(), color: Colors.blueGrey),
                  DifficultyChip(difficulty: p.difficulty),
                  InfoChip(label: 'Answer: ${p.answer}', color: Colors.black87),
                  if (p.scheduledFor != null) InfoChip(label: p.scheduledFor!, color: Colors.teal),
                  InfoChip(label: '${p.attemptsCount} plays', color: Colors.grey),
                ]),
              ),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(p)),
            ),
          );
        },
      ),
    );
  }
}
