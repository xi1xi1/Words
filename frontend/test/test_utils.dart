import 'dart:convert';

import 'package:http/http.dart' as http;

/// A simple request router for tests.
///
/// Example:
/// final client = http.MockClient((req) async => router.handle(req));
class TestRequestRouter {
  final _handlers = <String, Future<http.Response> Function(http.Request)>{};

  void on(String method, String fullUrl, Future<http.Response> Function(http.Request) handler) {
    _handlers['${method.toUpperCase()} $fullUrl'] = handler;
  }

  Future<http.Response> handle(http.Request request) async {
    final key = '${request.method.toUpperCase()} ${request.url.toString()}';
    final handler = _handlers[key];
    if (handler == null) {
      return http.Response(
        jsonEncode({
          'code': 404,
          'message': 'No mock handler for $key',
          'data': null,
        }),
        404,
        headers: {'content-type': 'application/json'},
      );
    }
    return handler(request);
  }
}

http.Response jsonResponse(
  int statusCode,
  Map<String, dynamic> body, {
  Map<String, String>? headers,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {
      'content-type': 'application/json',
      ...?headers,
    },
  );
}
