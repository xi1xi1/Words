// lib/core/constants/api_constants.dart
class ApiConstants {
  // 基础URL
  static const String baseUrl = 'http://172.20.10.2:8080/api';
  // 使用你的本地 Mock 地址
  // static const String baseUrl = 'http://127.0.0.1:4523/m1/7994468-7748376-7360578';
  static const String productionUrl = 'https://api.beileme.com/api';

  // 超时配置
  static const int connectTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000; // 30秒
  static const int sendTimeout = 30000; // 30秒

  // 认证相关
  static const String tokenKey = 'auth_token';
  static const String userInfoKey = 'user_info';

  // API 路径
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';

  static const String userProfile = '/user/profile';
  static const String userPassword = '/user/password';

  static const String wordsDaily = '/words/daily';
  static const String wordsLearn = '/words/learn';
  static const String wordsSearch = '/words/search';
  static const String wordsDetail = '/words';

  static const String challengeStart = '/challenge/start';
  static const String challengeSubmit = '/challenge/submit';
  static const String challengeRecords = '/challenge/records';

  static const String leaderboard = '/leaderboard';

  static const String wordbookList = '/wordbook/list';
  static const String wordbookAdd = '/wordbook/add';
  static const String wordbookRemove = '/wordbook/remove';
  static const String wordbookAi = '/wordbook/ai';

  static const String studyStats = '/study/stats';
  static const String studyTrend = '/study/trend';
  static const String studyCalendar = '/study/calendar';
}
