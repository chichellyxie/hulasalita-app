import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/puzzle.dart';
import '../repositories/puzzle_repository.dart';

/// List of Bugtong / Word Scramble / Translate It puzzles with filters.
class PuzzleListProvider extends ChangeNotifier {
  PuzzleListProvider(this._repo, this.type);

  final PuzzleRepository _repo;
  final String type;

  String? language; // en | fil | pag | null (all)
  String? difficulty; // easy | medium | hard | null (all)

  final List<Puzzle> items = [];
  bool loading = false;
  bool loadingMore = false;
  String? error;
  int _page = 1;
  bool _hasMore = false;

  bool get hasMore => _hasMore;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _repo.list(type: type, language: language, difficulty: difficulty, page: 1);
      items
        ..clear()
        ..addAll(page.items);
      _page = page.currentPage;
      _hasMore = page.hasMore;
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || loadingMore || loading) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.list(type: type, language: language, difficulty: difficulty, page: _page + 1);
      items.addAll(page.items);
      _page = page.currentPage;
      _hasMore = page.hasMore;
    } on ApiException catch (e) {
      error = e.message;
    }
    loadingMore = false;
    notifyListeners();
  }

  void setLanguage(String? value) {
    language = value;
    refresh();
  }

  void setDifficulty(String? value) {
    difficulty = value;
    refresh();
  }
}
