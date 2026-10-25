import 'dart:typed_data';

import '../core/api_service.dart';
import '../models/admin_models.dart';
import '../models/json.dart';
import '../models/language.dart';
import '../models/paginated.dart';
import '../models/school.dart';

/// Every /admin endpoint.
class AdminRepository {
  AdminRepository(this._api);

  final ApiService _api;

  // ---- Verification queue ----
  Future<Paginated<AdminVerification>> verifications({int page = 1}) async =>
      Paginated.fromJson(await _api.get('/admin/verifications', query: {'page': page}), AdminVerification.fromJson);

  Future<Uint8List> verificationDocument(int id) => _api.getBytes('/admin/verifications/$id/document');

  Future<void> decide(int id, String decision) async {
    await _api.patch('/admin/verifications/$id', data: {'decision': decision});
  }

  // ---- Puzzles ----
  Future<Paginated<AdminPuzzle>> puzzles({int page = 1, String? type, String? search}) async => Paginated.fromJson(
        await _api.get('/admin/puzzles', query: {'page': page, 'type': type, 'search': search}),
        AdminPuzzle.fromJson,
      );

  Future<AdminPuzzle> createPuzzle(Map<String, dynamic> body) async =>
      AdminPuzzle.fromJson(asMap(asMap(await _api.post('/admin/puzzles', data: body))['data']));

  Future<AdminPuzzle> updatePuzzle(int id, Map<String, dynamic> body) async =>
      AdminPuzzle.fromJson(asMap(asMap(await _api.put('/admin/puzzles/$id', data: body))['data']));

  Future<void> deletePuzzle(int id) async => _api.delete('/admin/puzzles/$id');

  // ---- Schools ----
  Future<List<School>> schools() async =>
      asList(asMap(await _api.get('/admin/schools'))['data']).map((e) => School.fromJson(asMap(e))).toList();

  Future<void> saveSchool({int? id, required String name, String? barangay, required bool isActive}) async {
    final body = {'name': name.trim(), 'barangay': barangay?.trim(), 'is_active': isActive};
    if (id == null) {
      await _api.post('/admin/schools', data: body);
    } else {
      await _api.put('/admin/schools/$id', data: body);
    }
  }

  Future<void> deleteSchool(int id) async => _api.delete('/admin/schools/$id');

  // ---- Categories ----
  Future<List<PuzzleCategory>> categories() async =>
      asList(asMap(await _api.get('/admin/categories'))['data']).map((e) => PuzzleCategory.fromJson(asMap(e))).toList();

  Future<void> saveCategory({int? id, required String name}) async {
    final body = {'name': name.trim()};
    if (id == null) {
      await _api.post('/admin/categories', data: body);
    } else {
      await _api.put('/admin/categories/$id', data: body);
    }
  }

  Future<void> deleteCategory(int id) async => _api.delete('/admin/categories/$id');

  // ---- Languages ----
  Future<List<Language>> languages() async =>
      asList(asMap(await _api.get('/admin/languages'))['data']).map((e) => Language.fromJson(asMap(e))).toList();

  Future<void> saveLanguage({int? id, required String code, required String name}) async {
    final body = {'code': code.trim().toLowerCase(), 'name': name.trim()};
    if (id == null) {
      await _api.post('/admin/languages', data: body);
    } else {
      await _api.put('/admin/languages/$id', data: body);
    }
  }

  Future<void> deleteLanguage(int id) async => _api.delete('/admin/languages/$id');

  // ---- Users ----
  Future<Paginated<AdminUser>> users({int page = 1, String? search, String? status}) async => Paginated.fromJson(
        await _api.get('/admin/users', query: {'page': page, 'search': search, 'status': status}),
        AdminUser.fromJson,
      );

  Future<void> setUserActive(int id, bool active) async {
    await _api.patch('/admin/users/$id', data: {'is_active': active});
  }

  // ---- Reports ----
  Future<AdminReport> report({String? from, String? to}) async =>
      AdminReport.fromJson(asMap(asMap(await _api.get('/admin/reports', query: {'from': from, 'to': to}))['data']));
}
