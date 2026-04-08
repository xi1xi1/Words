import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../services/auth_service.dart';

/// 设置（外观 / 学习 / 其他）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminder = true;
  bool _autoSpeak = false;
  bool _loggingOut = false;
  final AuthService _authService = AuthService();

  static const _headerBlue = Color(0xFF5B86FF);

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<SettingsProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionTitle('外观设置'),
                _card([
                  _toggleRow(
                    icon: Icons.dark_mode_outlined,
                    label: '深色模式',
                    value: dark,
                    onChanged: (v) => context.read<SettingsProvider>().toggleTheme(),
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('学习设置'),
                _card([
                  _valueRow(Icons.track_changes_outlined, '每日学习目标', '30 词/天'),
                  _divider(context),
                  _toggleRow(
                    icon: Icons.notifications_outlined,
                    label: '学习提醒',
                    value: _reminder,
                    onChanged: (v) => setState(() => _reminder = v),
                  ),
                  _divider(context),
                  _toggleRow(
                    icon: Icons.volume_up_outlined,
                    label: '自动发音',
                    value: _autoSpeak,
                    onChanged: (v) => setState(() => _autoSpeak = v),
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('其他'),
                _card([
                  _valueRow(Icons.language_outlined, '语言设置', '简体中文'),
                  _divider(context),
                  _valueRow(Icons.info_outline, '关于', '版本 1.0.0'),
                ]),
                const SizedBox(height: 24),
                _logoutCard(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 4, 16, 24),
      decoration: const BoxDecoration(
        color: _headerBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: Color(0xFFFF9F43), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text(
                  'U',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习者',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: 123456',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? const Color(0xFF9AA3AF) : const Color(0xFF888888),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? const Color(0xFF2B3138) : const Color(0xFFEFEFEF),
    );
  }

  Widget _valueRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? const Color(0xFFCDD5DF) : const Color(0xFF666666), size: 22),
      title: Text(
        label,
        style: TextStyle(color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF333333), fontSize: 15),
      ),
      trailing: Text(
        value,
        style: TextStyle(color: isDark ? const Color(0xFF9AA3AF) : const Color(0xFF8E9297), fontSize: 14),
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? const Color(0xFFCDD5DF) : const Color(0xFF666666), size: 22),
      title: Text(
        label,
        style: TextStyle(color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF333333), fontSize: 15),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: _headerBlue.withValues(alpha: 0.45),
        activeThumbColor: Colors.white,
        onChanged: onChanged,
      ),
    );
  }

  Widget _logoutCard(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _loggingOut
            ? null
            : () async {
                final userProvider = context.read<UserProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);
                setState(() => _loggingOut = true);
                try {
                  await _authService.logout();
                  if (!mounted) return;
                  await userProvider.clearAuth();
                  if (!mounted) return;
                  router.go('/login');
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('退出失败，请重试'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _loggingOut = false);
                }
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: _loggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF4D4F),
                  ),
                )
              : const Text(
                  '退出登录',
                  style: TextStyle(
                    color: Color(0xFFFF4D4F),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
