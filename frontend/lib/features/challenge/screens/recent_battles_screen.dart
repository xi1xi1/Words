import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _Battle {
  final String levelLabel;
  final Color badgeColor;
  final String time;
  final String score;
  final bool up;
  final String detail;
  final List<String> words;

  const _Battle({
    required this.levelLabel,
    required this.badgeColor,
    required this.time,
    required this.score,
    required this.up,
    required this.detail,
    required this.words,
  });
}

/// 最近战绩
class RecentBattlesScreen extends StatelessWidget {
  const RecentBattlesScreen({super.key});

  static const _primary = Color(0xFF4A7DFF);
  static const _bg = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    const battles = [
      _Battle(
        levelLabel: '中级场',
        badgeColor: Color(0xFF4A7DFF),
        time: '今天 15:30',
        score: '72%',
        up: true,
        detail: '用时 8分30秒   18/25 题',
        words: ['serendipity', 'ephemeral'],
      ),
      _Battle(
        levelLabel: '初级场',
        badgeColor: Color(0xFF66CC77),
        time: '昨天 18:12',
        score: '85%',
        up: false,
        detail: '用时 5分10秒   20/25 题',
        words: ['resilience', 'eloquent'],
      ),
      _Battle(
        levelLabel: '高级场',
        badgeColor: Color(0xFFFFA04D),
        time: '3月28日',
        score: '61%',
        up: true,
        detail: '用时 12分20秒   15/25 题',
        words: ['ubiquitous'],
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _statsGrid(),
                const SizedBox(height: 20),
                const Text(
                  '历史记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 12),
                ...battles.map(_battleCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 16, 24),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
          const SizedBox(height: 4),
          const Text(
            '最近战绩',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '查看你的闯关历史记录',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    Widget cell(String label, String value, Color valueColor) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cell('总场次', '8', const Color(0xFF1A1A1B))),
            const SizedBox(width: 12),
            Expanded(child: cell('平均分', '72%', _primary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cell('最高分', '90%', const Color(0xFF66CC77))),
            const SizedBox(width: 12),
            Expanded(child: cell('正确率', '67%', const Color(0xFF1A1A1B))),
          ],
        ),
      ],
    );
  }

  Widget _battleCard(_Battle b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: b.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  b.levelLabel,
                  style: TextStyle(color: b.badgeColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(b.time, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
              ),
              Text(
                b.score,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                b.up ? Icons.trending_up : Icons.trending_down,
                color: b.up ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(b.detail, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
          const Divider(height: 24),
          const Text('涉及单词', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...b.words.map(
                (w) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    w,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF444444)),
                  ),
                ),
              ),
              Text(
                '+22 个',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
