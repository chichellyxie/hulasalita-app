import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/leaderboard.dart';
import '../repositories/stats_repository.dart';

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider(this._repo);

  final StatsRepository _repo;

  Leaderboard? board;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      board = await _repo.leaderboard();
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  void clear() {
    board = null;
    error = null;
    notifyListeners();
  }
}
