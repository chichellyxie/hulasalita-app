import 'package:dio/dio.dart';

/// One error type for the whole app. Screens show [message] and, for
/// 422 responses, the per-field messages in [fieldErrors].
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.accountStatus,
    this.isNetwork = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;
  final String? accountStatus; // pending | rejected | inactive (from 403)
  final bool isNetwork;

  String? fieldError(String field) {
    final errors = fieldErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  factory ApiException.fromDio(DioException e) {
    final response = e.response;

    if (response == null) {
      return ApiException(
        message: 'Cannot reach the HulaSalita server. Check your connection and try again.',
        isNetwork: true,
      );
    }

    final data = response.data;
    String message = 'Something went wrong (error ${response.statusCode}).';
    final fields = <String, List<String>>{};
    String? accountStatus;

    if (data is Map) {
      if (data['message'] is String) message = data['message'] as String;
      if (data['status'] is String) accountStatus = data['status'] as String;
      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          if (value is List) {
            fields[key.toString()] = value.map((v) => v.toString()).toList();
          }
        });
      }
    }

    if (response.statusCode == 429) {
      message = 'Too many attempts. Please wait a minute and try again.';
    }

    return ApiException(
      message: message,
      statusCode: response.statusCode,
      fieldErrors: fields,
      accountStatus: accountStatus,
    );
  }

  @override
  String toString() => message;
}
