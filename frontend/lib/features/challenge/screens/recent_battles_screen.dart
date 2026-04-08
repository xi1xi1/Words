import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/challenge_service.dart';
import '../../../models/challenge_model.dart';
import '../../../core/network/api_exception.dart';

class RecentBattlesScreen extends StatefulWidget {
  const RecentBattlesScreen({super.key});

  @override
  State<RecentBattlesScreen> createState() => _RecentBattlesScreenState();
}

class _RecentBattlesScreenState extends State<RecentBattlesScreen> {
  final ChallengeService _service = ChallengeService();

  bool _loading = true;
  List<BattleRecord> _records = [];
  int _totalBattles = 0;
  double _avgAccuracy = 0;
  int _maxScore = 0;

  static const _primary = Color(0xFF4A7DFF);
  static const _bg = Color(0xFFF7F8FA);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final records = await _service.getChallengeRecords(size: 50);
      if (mounted) {
        _records = records;
        _calculateStats();
        setState(() => _loading = false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _calculateStats() {
    _totalBattles = _records.length;
    if (_records.isEmpty) {
      _avgAccuracy = 0;
      _maxScore = 0;
      return;
    }

    double totalAcc = 0;
    int maxScore = 0;
    for (final r in _records) {
      final acc = r.totalCount > 0 ? r.correctCount / r.totalCount : 0.0;
      totalAcc += acc;
      if (r.score > maxScore) maxScore = r.score;
    }
    _avgAccuracy = totalAcc / _records.length;
    _maxScore = maxScore;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _statsGrid(),
                        const SizedBox(height: 20),
                        const Text(
                          '历史记录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_records.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                '暂无闯关记录',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            ),
                          )
                        else
                          ..._records.map(_battleCard),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        16,
        24,
      ),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(height: 4),
          const Text(
            '最近战绩',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '查看你的闯关历史记录',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
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
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    final avgPct = (_avgAccuracy * 100).round();
    final totalScore = _records.fold<int>(0, (sum, r) => sum + r.score);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: cell('总场次', '$_totalBattles', const Color(0xFF1A1A1B)),
            ),
            const SizedBox(width: 12),
            Expanded(child: cell('平均分', '$avgPct%', _primary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cell('最高分', '$_maxScore', const Color(0xFF66CC77))),
            const SizedBox(width: 12),
            Expanded(
              child: cell('累计积分', '$totalScore', const Color(0xFF1A1A1B)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _battleCard(BattleRecord record) {
    final accuracy = record.totalCount > 0
        ? (record.correctCount / record.totalCount * 100).round()
        : 0;
    final levelColor = _getLevelColor(record.levelType);
    final timeStr = _formatTime(record.createTime);

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.levelTypeName,
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$accuracy%',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                accuracy >= 60 ? Icons.trending_up : Icons.trending_down,
                color: accuracy >= 60
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '得分 ${record.score}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                '${record.correctCount}/${record.totalCount} 题',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
              if (record.duration != null) ...[
                const SizedBox(width: 16),
                Text(
                  '用时 ${record.duration! ~/ 60}分${record.duration! % 60}秒',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int levelType) {
    switch (levelType) {
      case 1:
        return const Color(0xFF66CC77);
      case 2:
        return _primary;
      case 3:
        return const Color(0xFFFFA04D);
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return '${weekdays[time.weekday - 1]} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}月${time.day}日';
    }
  }
}
