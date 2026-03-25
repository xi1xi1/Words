// lib/core/network/api_exception.dart
class ApiException implements Exception {
  final int code;
  final String message;
  final List<Map<String, String>>? errors;

  ApiException({required this.code, required this.message, this.errors});

  factory ApiException.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>>? errors;
    if (json['errors'] != null) {
      errors = (json['errors'] as List<dynamic>)
          .map(
            (e) => {
              'field': e['field'] as String,
              'message': e['message'] as String,
            },
          )
          .toList();
    }
    return ApiException(
      code: json['code'] as int,
      message: json['message'] as String,
      errors: errors,
    );
  }

  @override
  String toString() => 'ApiException($code): $message';
}
