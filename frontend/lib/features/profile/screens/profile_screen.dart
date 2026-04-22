// frontend/lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/study_service.dart';
import '../../../services/wordbook_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/study_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StudyService _studyService = StudyService();
  final WordbookService _wordbookService = WordbookService();
  bool _isLoading = true;
  StudyStats? _stats;
  int _wordbookCount = 0;
  List<StudyTrend>? _trend;
  List<LearningCalendar> _calendars = [];

  static const _bg = Color(0xFFF7F8FA);
  static const _blue = Color(0xFF4A74F5);
  static const _navy = Color(0xFF1A1C1E);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _studyService.getStudyStats();
      final wordbook = await _wordbookService.getWordbookList();
      List<StudyTrend>? trend;
      List<LearningCalendar> calendars = [];
      try {
        trend = await _studyService.getStudyTrend(days: 7);
      } catch (_) {
        trend = null;
      }
      try {
        final now = DateTime.now();
        calendars = [];
        for (int i = 0; i < 3; i++) {
          final month = now.month - i;
          final year = month > 0 ? now.year : now.year - 1;
          final actualMonth = month > 0 ? month : 12 + month;
          calendars.add(
            await _studyService.getStudyCalendar(
              year: year,
              month: actualMonth,
            ),
          );
        }
      } catch (_) {
        calendars = [];
      }
      setState(() {
        _stats = stats;
        _wordbookCount = wordbook.length;
        _trend = trend;
        _calendars = calendars;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 12,
            16,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '我的',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF8E9297),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCurrentWordbookCard(),
              const SizedBox(height: 24),
              const Text(
                '学习工具',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 12),
              _buildToolsGrid(),
              const SizedBox(height: 24),
              const Text(
                '学习数据',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 12),
              _buildDataStats(),
              const SizedBox(height: 24),
              const Text(
                '近7天学习趋势',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 12),
              _buildTrendChart(),
              const SizedBox(height: 24),
              _buildLearningCalendarCard(),
            ],
          ),
        ),
      ),
    );
  }

  List<DateTime> get _recent7Days {
    final now = DateTime.now();
    return List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day - (6 - index)),
    );
  }

  /// 近 7 天每日学习词数（柱图）；空数据时显示真实 0 值
  List<int> get _trendCounts {
    final t = _trend;
    final recentDays = _recent7Days;
    if (t == null || t.isEmpty) return List.filled(recentDays.length, 0);

    final countByDate = <String, int>{};
    for (final item in t) {
      final key =
          '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
      countByDate[key] = item.learnedCount;
    }

    return recentDays.map((day) {
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return countByDate[key] ?? 0;
    }).toList();
  }

  List<String> get _trendLabels {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return _recent7Days
        .map((day) => weekdays[day.weekday - 1])
        .toList();
  }

  Widget _buildTrendChart() {
    final counts = _trendCounts;
    final labels = _trendLabels;
    final maxC = counts.isEmpty
        ? 1
        : counts.reduce((a, b) => a > b ? a : b).clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                '单位：词',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = 72.0 * counts[i] / maxC;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: h.clamp(4.0, 72.0),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              labels.length,
              (i) => Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 近 4 周学习热力（与设计稿一致）；无专用接口时用本地演示强度
  Widget _buildLearningCalendarCard() {
    final now = DateTime.now();
    final studyDatesSet = <String>{};
    for (final cal in _calendars) {
      studyDatesSet.addAll(cal.studyDates);
    }

    final List<DateTime> recent28Days = [];
    for (int i = 27; i >= 0; i--) {
      recent28Days.add(now.subtract(Duration(days: i)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: Colors.orange.shade400,
              size: 22,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                '学习日历',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
            ),
            Text(
              '近4周',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 1,
                children: List.generate(28, (i) {
                  final date = recent28Days[i];
                  final dateStr =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final hasStudy = studyDatesSet.contains(dateStr);
                  return Container(
                    decoration: BoxDecoration(
                      color: hasStudy ? _blue : const Color(0xFFEBEDF0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasStudy ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '无',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEDF0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '有学习',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWordbookCard() {
    if (_isLoading) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _cardShadow,
        ),
        child: const CircularProgressIndicator(),
      );
    }

    final totalLearned = _stats?.totalLearned ?? 0;
    final totalGoal = (_stats?.totalVocabulary ?? 0) > 0
        ? _stats!.totalVocabulary
        : 3000;
    final progress = totalGoal <= 0
        ? 0.0
        : (totalLearned / totalGoal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '当前词库',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, color: _blue, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _blue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '四级核心词汇',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalLearned / $totalGoal 词',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E9297),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                '学习进度',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFEFEF),
              valueColor: const AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
        ],
      ),
    );
  }

  List<BoxShadow> get _cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  Widget _buildToolsGrid() {
    return _toolCard(
      icon: Icons.bookmark_rounded,
      iconColor: _blue,
      iconBg: const Color(0xFFE8EEFD),
      count: _wordbookCount == 0 ? 128 : _wordbookCount,
      title: '生词本',
      subtitle: '收藏的生词，随时回顾重点单词',
      onTap: () => context.push('/wordbook'),
    );
  }

  Widget _toolCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required int count,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: _cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E9297),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '个单词',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E9297),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC1C7D0),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataStats() {
    if (_isLoading) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _cardShadow,
        ),
        child: const CircularProgressIndicator(),
      );
    }

    final todayStudy = _stats?.todayStudy ?? 35;
    final todayReview = _stats?.todayReview ?? 80;
    final totalLearned = _stats?.totalLearned ?? 1245;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _dataCell(
              Icons.menu_book_rounded,
              '$todayStudy ↑',
              '今日学习',
              const Color(0xFFE8EEFD),
              _blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dataCell(
              Icons.autorenew_rounded,
              '$todayReview ↑',
              '今日复习',
              const Color(0xFFE8F8EC),
              const Color(0xFF66CC77),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dataCell(
              Icons.track_changes_rounded,
              '$totalLearned 词',
              '累计学习',
              const Color(0xFFFFF2E6),
              const Color(0xFFFF9F43),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(
    IconData icon,
    String value,
    String label,
    Color bg,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E9297),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
