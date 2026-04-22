import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/core/network/api_exception.dart';

void main() {
  test('ApiException.fromJson parses code/message and errors list', () {
    final e = ApiException.fromJson({
      'code': 400,
      'message': 'bad',
      'errors': [
        {'field': 'username', 'message': 'required'},
        {'field': 'password', 'message': 'too short'},
      ],
    });

    expect(e.code, 400);
    expect(e.message, 'bad');
    expect(e.errors, isNotNull);
    expect(e.errors!.length, 2);
    expect(e.errors!.first['field'], 'username');
  });

  test('ApiException.toString includes code and message', () {
    final e = ApiException(code: 500, message: 'oops');
    expect(e.toString(), contains('500'));
    expect(e.toString(), contains('oops'));
  });
}
