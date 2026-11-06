import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../models/saved_word.dart';
import '../../repositories/puzzle_repository.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';
import '../../widgets/kwago.dart';
import '../../widgets/learn_card.dart';

/// Saved words to review: tap a word to open its Learn card.
class WordBankScreen extends StatefulWidget {
  const WordBankScreen({super.key});

  @override
  State<WordBankScreen> createState() => _WordBankScreenState();
}

class _WordBankScreenState extends State<WordBankScreen> {
  List<SavedWord> _words = [];
  bool _loading = true;
  String? _error;
  String? _language; // filter: en | fil | pag | null

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _words = await context.read<PuzzleRepository>().wordBank();
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _remove(SavedWord w) async {
    try {
      await context.read<PuzzleRepository>().removeWord(w.puzzleId);
      if (!mounted) return;
      setState(() => _words.removeWhere((x) => x.puzzleId == w.puzzleId));
      showSnack(context, 'Removed "${w.answer}" from your Word Bank.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  void _open(SavedWord w) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(PuzzleType.label(w.type), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(w.prompt, style: displayStyle(size: 20, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              LearnCardView(answer: w.answer, learn: w.learn),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _language == null ? _words : _words.where((w) => w.language?.code == _language).toList();

    return Scaffold(
      backgroundColor: AppColors.night,
      body: Column(
        children: [
          AppHeader(
            title: 'My Word Bank',
            emoji: '🔖',
            subtitle: '${_words.length} saved word${_words.length == 1 ? '' : 's'}',
            showBack: true,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (code, label) in const <(String?, String)>[(null, 'All'), ('en', 'English'), ('fil', 'Filipino'), ('pag', 'Pangasinan')])
                  Material(
                    color: _language == code ? AppColors.gold : Colors.white.withValues(alpha: 0.14),
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => setState(() => _language = code),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Text(label,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _language == code ? AppColors.ink : Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _body(shown)),
        ],
      ),
    );
  }

  Widget _body(List<SavedWord> shown) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load, onNight: true);
    if (_words.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Kwago(message: 'Wala ka pang naka-save. Pagkatapos ng puzzle, i-tap ang "Save to Word Bank"!'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: shown.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final w = shown[i];
          final english = w.learn?.translations['en'];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(w),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.answer, style: displayStyle(size: 22)),
                          if (english != null && english.toLowerCase() != w.answer.toLowerCase())
                            Text(english, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            if (w.language != null) Pill(label: w.language!.name),
                            Pill(label: PuzzleType.label(w.type), background: AppColors.background, foreground: AppColors.muted),
                          ]),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => _remove(w),
                      icon: const Icon(Icons.bookmark_remove_outlined, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
