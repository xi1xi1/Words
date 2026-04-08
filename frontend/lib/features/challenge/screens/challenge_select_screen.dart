// frontend/lib/features/challenge/screens/challenge_select_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/challenge_service.dart';
import '../../../services/leaderboard_service.dart';
import '../../../models/leaderboard_model.dart';
import '../../../core/network/api_exception.dart';

class ChallengeSelectScreen extends StatefulWidget {
  const ChallengeSelectScreen({super.key});

  @override
  State<ChallengeSelectScreen> createState() => _ChallengeSelectScreenState();
}

class _ChallengeSelectScreenState extends State<ChallengeSelectScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  bool _isLoading = false;
  bool _leaderboardLoading = true;
  int? _selectedLevel;
  List<LeaderboardEntry> _topEntries = [];

  static const _bg = Color(0xFFF7F8FA);
  static const _blue = Color(0xFF4D7CFF);
  static const _green = Color(0xFF66CC77);
  static const _orange = Color(0xFFFFA04D);

  final List<Map<String, dynamic>> _levels = [
    {
      'level': 1,
      'name': '初级场',
      'online': '1234 在线',
      'desc': '1000个基础单词',
      'best': '最佳: 85%',
      'iconBg': Color(0xFFE8F8EC),
      'iconColor': _green,
      'icon': Icons.bolt_rounded,
      'btnColor': _green,
    },
    {
      'level': 2,
      'name': '中级场',
      'online': '856 在线',
      'desc': '3000个进阶单词',
      'best': '最佳: 72%',
      'iconBg': Color(0xFFE8EEFD),
      'iconColor': _blue,
      'icon': Icons.adjust_rounded,
      'btnColor': _blue,
    },
    {
      'level': 3,
      'name': '高级场',
      'online': '423 在线',
      'desc': '6000个高级单词',
      'best': '最佳: 61%',
      'iconBg': Color(0xFFFFF2E6),
      'iconColor': _orange,
      'icon': Icons.emoji_events_outlined,
      'btnColor': _orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaderboardPreview();
  }

  Future<void> _loadLeaderboardPreview() async {
    setState(() => _leaderboardLoading = true);
    try {
      final result = await _leaderboardService.getLeaderboard(
        type: 'total',
        limit: 2,
      );
      if (!mounted) return;
      setState(() {
        _topEntries = result.entries.take(2).toList();
        _leaderboardLoading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _topEntries = [];
        _leaderboardLoading = false;
      });
    }
  }

  Future<void> _startChallenge(int levelType) async {
    setState(() {
      _isLoading = true;
      _selectedLevel = levelType;
    });

    try {
      final response = await _challengeService.startChallenge(levelType);
      final level = _levels.firstWhere((e) => e['level'] == levelType);

      if (mounted) {
        context.push(
          '/challenge-game',
          extra: {
            'challengeId': response.challengeId,
            'questions': response.questions,
            'timeLimit': response.timeLimit,
            'levelType': levelType,
            'levelName': level['name'] as String,
            'accentColor': level['btnColor'] as Color,
          },
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedLevel = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _heroHeader(topPad)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      '选择挑战场次',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._levels.map(_sessionCard),
                    const SizedBox(height: 8),
                    _leaderboardSection(context),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () => context.push('/recent-battles'),
                        icon: const Icon(Icons.history, size: 18, color: _blue),
                        label: const Text('最近战绩', style: TextStyle(color: _blue)),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          if (_isLoading) _loadingOverlay(),
        ],
      ),
    );
  }

  Widget _heroHeader(double topPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
      decoration: const BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '闯关挑战',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '通过游戏化闯关，提升单词记忆效率',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> level) {
    final btnColor = level['btnColor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: level['iconBg'] as Color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(level['icon'] as IconData, color: level['iconColor'] as Color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      level['name'] as String,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        level['online'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  level['desc'] as String,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF636E72)),
                ),
                const SizedBox(height: 8),
                Text(
                  level['best'] as String,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: _isLoading ? null : () => _startChallenge(level['level'] as int),
              style: FilledButton.styleFrom(
                backgroundColor: btnColor,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('开始挑战', style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardSection(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/leaderboard'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: _orange, size: 22),
                  const SizedBox(width: 6),
                  const Text(
                    '全服排行榜',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                  ),
                  const Spacer(),
                  const Text(
                    '查看详情',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_leaderboardLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_topEntries.isEmpty) ...[
                const Text(
                  '暂无排行榜数据',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _loadLeaderboardPreview,
                  child: const Text('重新加载'),
                ),
              ] else ...[
                for (var i = 0; i < _topEntries.length; i++) ...[
                  _miniRank(
                    _iconForRank(_topEntries[i].rank),
                    _colorForRank(_topEntries[i].rank),
                    _topEntries[i].username,
                    '${_topEntries[i].score} 积分',
                  ),
                  if (i != _topEntries.length - 1) const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForRank(int rank) {
    if (rank == 1) return Icons.emoji_events;
    if (rank == 2) return Icons.workspace_premium;
    return Icons.person_outline;
  }

  Color _colorForRank(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return const Color(0xFFB0BEC5);
    return const Color(0xFFCCCCCC);
  }

  Widget _miniRank(IconData icon, Color iconColor, String name, subtitle) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text('加载中...', style: TextStyle(color: Colors.white, fontSize: 16)),
            if (_selectedLevel != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '正在准备${_levels.firstWhere((e) => e['level'] == _selectedLevel)['name']}题目',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
