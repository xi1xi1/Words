import 'package:flutter/material.dart';

// ========== 颜色常量 ==========
class AppColors {
  // 浅色模式
  static const primaryLight = Color(0xFF4F7CFF);
  static const secondaryLight = Color(0xFF6BCB77);
  static const accentLight = Color(0xFFFF9F43);
  static const backgroundLight = Color(0xFFF7F9FC);
  static const cardLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1F2937);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const dividerLight = Color(0xFFE5E7EB);

  // 深色模式
  static const primaryDark = Color(0xFF6D8CFF);
  static const secondaryDark = Color(0xFF7EDC8D);
  static const accentDark = Color(0xFFFFB86B);
  static const backgroundDark = Color(0xFF121212);
  static const cardDark = Color(0xFF1E1E1E);
  static const textPrimaryDark = Color(0xFFF3F4F6);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const dividerDark = Color(0xFF2C2C2C);
}

// ========== 字体样式 ==========
class AppTextStyles {
  static const title1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    fontFamily: 'PingFangSC',
  );

  static const title2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'PingFangSC',
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: 'PingFangSC',
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: 'PingFangSC',
  );
}

// ========== 字符串常量 ==========
class AppStrings {
  static const appName = '背了么';
  static const home = '首页';
  static const challenge = '闯关';
  static const profile = '我的';
  static const study = '学习';
  static const review = '复习';
  static const wordbook = '生词本';
  static const settings = '设置';
}

// ========== 配置常量 ==========
class AppConfig {
  static const apiBaseUrl = 'http://localhost:8080/api';
  static const timeoutSeconds = 30;
  static const pageSize = 20;
}
