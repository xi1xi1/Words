import 'package:flutter/material.dart';
import 'api_constants.dart';

// ========== 颜色常量 ==========
class AppColors {
  // 浅色模式（与 UI 稿对齐的主色）
  static const primaryLight = Color(0xFF4D7CFF);
  static const secondaryLight = Color(0xFF66CC77);
  static const accentLight = Color(0xFFFFA04D);
  static const backgroundLight = Color(0xFFF7F8FA);
  static const cardLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1F2937);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const dividerLight = Color(0xFFE8E8E8);

  /// 设计稿专用别名
  static const designBlue = Color(0xFF4D7CFF);
  static const designGreen = Color(0xFF66CC77);
  static const designOrange = Color(0xFFFFA04D);
  static const designPageBg = Color(0xFFF7F8FA);
  static const designNavy = Color(0xFF1A2B48);
  static const designTextBody = Color(0xFF2D3436);
  static const designMuted = Color(0xFF636E72);
  static const designBorder = Color(0xFFE0E0E0);

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
  static const apiBaseUrl = ApiConstants.baseUrl;
  static const timeoutSeconds = 30;
  static const pageSize = 20;
}
