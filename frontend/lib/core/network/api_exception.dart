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

  String get safeMessage {
    switch (code) {
      case -1:
        return '网络连接失败，请检查网络设置';
      case 400:
        return '请求参数有误，请检查输入';
      case 401:
        return '登录状态已失效，请重新登录';
      case 403:
        return '当前账号无权执行该操作';
      case 404:
        return '请求的资源不存在';
      case 500:
      case 502:
      case 503:
      case 504:
        return '服务器开小差了，请稍后重试';
      default:
        if (code >= 500) {
          return '服务器开小差了，请稍后重试';
        }
        if (code >= 400) {
          return '操作失败，请检查输入后重试';
        }
        return message.isNotEmpty ? message : '操作失败，请稍后重试';
    }
  }

  @override
  String toString() => 'ApiException($code): $message';
}
