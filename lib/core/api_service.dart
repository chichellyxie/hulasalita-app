import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'config.dart';
import 'token_storage.dart';

/// The only class that talks HTTP. Repositories call it; widgets never do.
///
/// The interceptor:
///  - attaches `Authorization: Bearer <token>` to every request
///  - calls [onUnauthorized] on 401 (token missing/expired → sign out)
///  - calls [onAccountStatus] on 403 with a status (pending/rejected/inactive)
class ApiService {
  ApiService(this._tokens)
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              'Accept': 'application/json',
              // Skips ngrok's free-plan warning page (harmless everywhere else).
              'ngrok-skip-browser-warning': '1',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final data = error.response?.data;

          if (status == 401 && !path.contains('auth/login')) {
            onUnauthorized?.call();
          } else if (status == 403 && data is Map && data['status'] is String) {
            onAccountStatus?.call(data['status'] as String);
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokens;

  void Function()? onUnauthorized;
  void Function(String status)? onAccountStatus;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? data}) => _send(() => dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) => _send(() => dio.put(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) => _send(() => dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _send(() => dio.delete(path));

  /// Multipart upload (school ID photo).
  Future<dynamic> upload(String path, {required String field, required String filePath}) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final form = FormData.fromMap({
      field: await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _send(() => dio.post(path, data: form));
  }

  /// Raw bytes (admin: private school ID image).
  Future<Uint8List> getBytes(String path) async {
    try {
      final response = await dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? <int>[]);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final result = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) result[key] = value;
    });
    return result;
  }
}
