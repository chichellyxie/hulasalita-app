import '../core/api_service.dart';
import '../models/json.dart';
import '../models/language.dart';
import '../models/school.dart';

/// Schools, languages and categories — small lists kept in a memory cache.
class ReferenceRepository {
  ReferenceRepository(this._api);

  final ApiService _api;
  List<School>? _schools;
  List<Language>? _languages;
  List<PuzzleCategory>? _categories;

  Future<List<School>> schools({bool refresh = false}) async {
    if (_schools != null && !refresh) return _schools!;
    final data = asMap(await _api.get('/schools'));
    return _schools = asList(data['data']).map((e) => School.fromJson(asMap(e))).toList();
  }

  Future<List<Language>> languages({bool refresh = false}) async {
    if (_languages != null && !refresh) return _languages!;
    final data = asMap(await _api.get('/languages'));
    return _languages = asList(data['data']).map((e) => Language.fromJson(asMap(e))).toList();
  }

  Future<List<PuzzleCategory>> categories({bool refresh = false}) async {
    if (_categories != null && !refresh) return _categories!;
    final data = asMap(await _api.get('/categories'));
    return _categories = asList(data['data']).map((e) => PuzzleCategory.fromJson(asMap(e))).toList();
  }

  void clear() {
    _schools = null;
    _languages = null;
    _categories = null;
  }
}
