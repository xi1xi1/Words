import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/core/network/api_exception.dart';

void main() {
  group('ApiException.safeMessage', () {
    test('maps network error to friendly message', () {
      final exception = ApiException(code: -1, message: 'SocketException');

      expect(exception.safeMessage, '网络连接失败，请检查网络设置');
    });

    test('maps common client errors to friendly messages', () {
      expect(
        ApiException(code: 400, message: 'SQL syntax error').safeMessage,
        '请求参数有误，请检查输入',
      );
      expect(
        ApiException(code: 401, message: 'JWT parse stack trace').safeMessage,
        '登录状态已失效，请重新登录',
      );
      expect(
        ApiException(code: 403, message: 'Forbidden').safeMessage,
        '当前账号无权执行该操作',
      );
      expect(
        ApiException(code: 404, message: 'Not found').safeMessage,
        '请求的资源不存在',
      );
    });

    test('maps server errors to generic server message', () {
      const expected = '服务器开小差了，请稍后重试';

      for (final code in [500, 502, 503, 504, 599]) {
        expect(
          ApiException(code: code, message: 'NullPointerException').safeMessage,
          expected,
        );
      }
    });

    test('maps unknown client error to generic operation failure', () {
      final exception = ApiException(code: 422, message: 'Validation stack');

      expect(exception.safeMessage, '操作失败，请检查输入后重试');
    });

    test('keeps non-error business message when it is safe to show', () {
      final exception = ApiException(code: 300, message: '今日学习任务已完成');

      expect(exception.safeMessage, '今日学习任务已完成');
    });

    test('falls back when non-error business message is empty', () {
      final exception = ApiException(code: 300, message: '');

      expect(exception.safeMessage, '操作失败，请稍后重试');
    });
  });
}
