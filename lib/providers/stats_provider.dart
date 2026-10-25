import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/stats.dart';
import '../repositories/stats_repository.dart';

class StatsProvider extends ChangeNotifier {
  StatsProvider(this._repo);

  final StatsRepository _repo;

  PlayerStats? stats;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      stats = await _repo.myStats();
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  void clear() {
    stats = null;
    error = null;
    notifyListeners();
  }
}
