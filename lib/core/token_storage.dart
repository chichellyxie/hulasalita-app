import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the Sanctum token in encrypted storage (never plain preferences).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'hulasalita_token';
  final FlutterSecureStorage _storage;
  String? _cached;

  Future<String?> read() async {
    _cached ??= await _storage.read(key: _key);
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
