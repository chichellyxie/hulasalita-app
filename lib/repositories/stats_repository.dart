import '../core/api_service.dart';
import '../models/json.dart';
import '../models/leaderboard.dart';
import '../models/stats.dart';

class StatsRepository {
  StatsRepository(this._api);

  final ApiService _api;

  Future<PlayerStats> myStats() async {
    final data = asMap(await _api.get('/me/stats'));
    return PlayerStats.fromJson(asMap(data['data']));
  }

  Future<Leaderboard> leaderboard() async {
    final data = asMap(await _api.get('/leaderboard'));
    return Leaderboard.fromJson(data);
  }
}
