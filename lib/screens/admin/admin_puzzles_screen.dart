import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/admin_models.dart';
import '../../models/puzzle.dart';
import '../../repositories/admin_repository.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';
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
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text('New puzzle', style: displayStyle(size: 17, color: AppColors.ink)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [null, ...PuzzleType.all].map((t) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(t == null ? 'All' : PuzzleType.label(t)),
                    showCheckmark: false,
                    selectedColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.line),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
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
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton(onPressed: _loading ? null : () => _load(more: true), child: const Text('Load more')),
            );
          }
          final p = _items[i];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openForm(p),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.prompt, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.35)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 5, runSpacing: 5, children: [
                              Pill(label: PuzzleType.label(p.type)),
                              if (p.language != null)
                                Pill(label: p.language!.code.toUpperCase(), background: const Color(0xFFEEF0F6), foreground: const Color(0xFF3A4060)),
                              Pill.difficulty(p.difficulty),
                              if (p.level != null && PuzzleType.leveled.contains(p.type))
                                Pill(label: SchoolLevel.shortLabel(p.level!), background: AppColors.background, foreground: AppColors.muted),
                              if (p.choices.isNotEmpty)
                                Pill(label: '${p.choices.length} choices', background: AppColors.contextSoft, foreground: AppColors.context),
                              if (p.scheduledFor != null)
                                Pill(label: p.scheduledFor!, background: AppColors.scrambleSoft, foreground: AppColors.scramble),
                            ]),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(children: [
                                      const TextSpan(text: 'Answer: '),
                                      TextSpan(text: p.answer, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      TextSpan(text: ' · ${p.attemptsCount} plays'),
                                    ]),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF3A4060)),
                                  ),
                                ),
                                Text(
                                  p.hasLearnCard ? 'Learn card ready' : 'Learn card missing',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: p.hasLearnCard ? AppColors.correct : AppColors.wrong,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete puzzle',
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
                        onPressed: () => _delete(p),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
