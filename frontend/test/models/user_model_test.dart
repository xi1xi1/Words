import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/models/user_model.dart';

void main() {
  test('UserInfo.fromJson/toJson/copyWith', () {
    final u = UserInfo.fromJson({
      'id': 1,
      'username': 'zhang',
      'avatar': 'a',
      'totalScore': 10,
      'level': 2,
    });

    expect(u.id, 1);
    expect(u.username, 'zhang');
    expect(u.totalScore, 10);

    final j = u.toJson();
    expect(j['username'], 'zhang');

    final u2 = u.copyWith(username: 'xin');
    expect(u2.username, 'xin');
    expect(u2.id, 1);
  });
}
