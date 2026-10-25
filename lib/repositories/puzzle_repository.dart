import '../core/api_service.dart';
import '../models/guess_result.dart';
import '../models/json.dart';
import '../models/paginated.dart';
import '../models/puzzle.dart';

class PuzzleRepository {
  PuzzleRepository(this._api);

  final ApiService _api;

  /// GET /puzzles/daily — throws ApiException(404) when none is scheduled.
  Future<Puzzle> daily() async {
    final data = asMap(await _api.get('/puzzles/daily'));
    return Puzzle.fromJson(asMap(data['data']));
  }

  Future<Paginated<Puzzle>> list({
    required String type,
    String? language,
    String? difficulty,
    int page = 1,
  }) async {
    final data = await _api.get('/puzzles', query: {
      'type': type,
      'language': language,
      'difficulty': difficulty,
      'page': page,
      'per_page': 20,
    });
    return Paginated.fromJson(data, Puzzle.fromJson);
  }

  Future<Puzzle> show(int id) async {
    final data = asMap(await _api.get('/puzzles/$id'));
    return Puzzle.fromJson(asMap(data['data']));
  }

  /// POST /puzzles/{id}/guess — the server checks the answer.
  Future<GuessResult> guess(int puzzleId, String guess) async {
    final data = asMap(await _api.post('/puzzles/$puzzleId/guess', data: {'guess': guess}));
    return GuessResult.fromJson(asMap(data['data']));
  }
}
