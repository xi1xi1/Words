// frontend/lib/features/challenge/screens/challenge_select_screen.dart
import 'package:flutter/material.dart';
import '../../../services/challenge_service.dart';
import '../../../core/network/api_exception.dart';
import 'challenge_game_screen.dart';

class ChallengeSelectScreen extends StatefulWidget {
  const ChallengeSelectScreen({super.key});

  @override
  State<ChallengeSelectScreen> createState() => _ChallengeSelectScreenState();
}

class _ChallengeSelectScreenState extends State<ChallengeSelectScreen> {
  final ChallengeService _challengeService = ChallengeService();
  bool _isLoading = false;
  int? _selectedLevel;

  final List<Map<String, dynamic>> _levels = [
    {
      'level': 1,
      'name': '初级场',
      'icon': Icons.sentiment_satisfied,
      'color': Color(0xFF6BCB77),
      'description': '基础词汇，适合新手',
      'difficulty': '⭐',
      'points': '+50',
    },
    {
      'level': 2,
      'name': '中级场',
      'icon': Icons.sentiment_neutral,
      'color': Color(0xFFFF9F43),
      'description': '常用词汇，略有挑战',
      'difficulty': '⭐⭐⭐',
      'points': '+100',
    },
    {
      'level': 3,
      'name': '高级场',
      'icon': Icons.sentiment_very_satisfied,
      'color': Color(0xFF4F7CFF),
      'description': '高阶词汇，高手对决',
      'difficulty': '⭐⭐⭐⭐⭐',
      'points': '+200',
    },
  ];

  Future<void> _startChallenge(int levelType) async {
    setState(() {
      _isLoading = true;
      _selectedLevel = levelType;
    });

    try {
      final response = await _challengeService.startChallenge(levelType);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeGameScreen(
              challengeId: response.challengeId,
              questions: response.questions,
              timeLimit: response.timeLimit,
            ),
          ),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('选择闯关场次'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  '选择你的挑战难度',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '场次越高，积分越多，挑战也越大',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // 场次卡片列表
                ..._levels.map((level) => _buildLevelCard(level)),

                const SizedBox(height: 24),

                // 排行榜入口
                _buildRankingEntry(),
              ],
            ),
          ),

          // 加载遮罩
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      '加载中...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (_selectedLevel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '正在准备${_levels.firstWhere((e) => e['level'] == _selectedLevel)['name']}题目',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> level) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _startChallenge(level['level']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (level['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(level['icon'], color: level['color'], size: 32),
            ),
            const SizedBox(width: 16),

            // 场次信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        level['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        level['difficulty'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level['description'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (level['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '积分 ${level['points']}',
                      style: TextStyle(
                        fontSize: 10,
                        color: level['color'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 箭头
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingEntry() {
    return GestureDetector(
      onTap: () {
        // 跳转到排行榜页面
        Navigator.pushNamed(context, '/leaderboard');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4F7CFF).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4F7CFF).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4F7CFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.leaderboard,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '全服排行榜',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '看看你和学霸的差距',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
