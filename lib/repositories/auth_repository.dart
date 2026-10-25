import '../core/api_service.dart';
import '../core/token_storage.dart';
import '../models/json.dart';
import '../models/user.dart';

/// Account access + school ID upload.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiService _api;
  final TokenStorage _tokens;

  Future<bool> hasToken() async => (await _tokens.read()) != null;

  Future<void> clearToken() => _tokens.clear();

  Future<AppUser> login({required String login, required String password}) async {
    final data = asMap(await _api.post('/auth/login', data: {
      'login': login.trim(),
      'password': password,
      'device_name': 'hulasalita-android',
    }));
    await _tokens.write(asString(data['token']));
    return AppUser.fromJson(asMap(data['user']));
  }

  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required int schoolId,
    required bool privacyAccepted,
  }) async {
    final data = asMap(await _api.post('/auth/register', data: {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'school_id': schoolId,
      'privacy_accepted': privacyAccepted,
      'device_name': 'hulasalita-android',
    }));
    await _tokens.write(asString(data['token']));
    return AppUser.fromJson(asMap(data['user']));
  }

  Future<AppUser> me() async {
    final data = asMap(await _api.get('/me'));
    return AppUser.fromJson(asMap(data['data']));
  }

  Future<AppUser> updateProfile({String? username, String? currentPassword, String? password, String? passwordConfirmation}) async {
    final body = <String, dynamic>{};
    if (username != null && username.trim().isNotEmpty) body['username'] = username.trim();
    if (password != null && password.isNotEmpty) {
      body['current_password'] = currentPassword ?? '';
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation ?? '';
    }
    final data = asMap(await _api.put('/me', data: body));
    return AppUser.fromJson(asMap(data['data']));
  }

  /// POST /verification — multipart field "id_image".
  Future<void> uploadSchoolId(String filePath) async {
    await _api.upload('/verification', field: 'id_image', filePath: filePath);
  }

  /// Revokes the token on the server (best effort) and always clears it locally.
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Offline or token already invalid — still sign out locally.
    } finally {
      await _tokens.clear();
    }
  }
}
