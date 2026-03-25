import 'package:flutter/material.dart';
import '../../../services/word_service.dart';
import '../../../models/word_model.dart';
import '../../study/screens/study_screen.dart';
import '../../challenge/screens/challenge_select_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const ChallengeSelectScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _pages[_currentIndex]);
  }
}

// 首页内容组件
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // 头像和欢迎语
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '下午好，',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '同学',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // 跳转到设置页面
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 学习卡片
          _buildStudyCard(context),

          const SizedBox(height: 16),

          // 复习卡片
          _buildReviewCard(context),

          const SizedBox(height: 24),

          // 今日推荐单词
          const Text(
            '今日推荐',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _DailyWordCard(),
        ],
      ),
    );
  }

  Widget _buildStudyCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudyScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F7CFF), Color(0xFF6B9AFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日学习',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '0 / 10',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '完成今日任务获得积分',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 跳转到复习页面
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '待复习',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '0',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9F43),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '个单词需要复习',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F43).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.autorenew, color: Color(0xFFFF9F43)),
            ),
          ],
        ),
      ),
    );
  }
}

// 今日推荐单词卡片
class _DailyWordCard extends StatefulWidget {
  const _DailyWordCard();

  @override
  State<_DailyWordCard> createState() => _DailyWordCardState();
}

class _DailyWordCardState extends State<_DailyWordCard> {
  final WordService _wordService = WordService();
  bool _isLoading = true;
  List<Word> _dailyWords = []; // 👈 改成这样
  List<Word> _reviewWords = []; // 👈 新增这一行

  @override
  void initState() {
    super.initState();
    _loadDailyWords();
  }

  Future<void> _loadDailyWords() async {
    setState(() => _isLoading = true);
    print('===== 开始加载单词 ====='); // 👈 添加

    try {
      final result = await _wordService.getDailyWords();
      print('API 返回成功'); // 👈 添加
      print('newWords: ${result.newWords.length}'); // 👈 添加
      print('reviewWords: ${result.reviewWords.length}'); // 👈 添加

      setState(() {
        _dailyWords = result.newWords;
        _reviewWords = result.reviewWords;
      });

      print('setState 完成，_dailyWords: ${_dailyWords.length}'); // 👈 添加
      print('setState 完成，_reviewWords: ${_reviewWords.length}'); // 👈 添加
    } catch (e) {
      print('加载失败: $e'); // 👈 添加
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print('加载结束'); // 👈 添加
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 👇 修改这里：检查新词和复习词是否都为空
    if (_dailyWords.isEmpty && _reviewWords.isEmpty) {
      return const Center(child: Text('今日没有新单词，去复习吧！'));
    }

    // 👇 修改这里：显示新词和复习词
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示新词
        if (_dailyWords.isNotEmpty) ...[
          const Text(
            '今日新词',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._dailyWords.map((word) => _buildWordCard(word)),
        ],

        // 显示复习词
        if (_reviewWords.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            '复习单词',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._reviewWords.map((word) => _buildWordCard(word)),
        ],
      ],
    );
  }

  // 👇 新增这个方法：显示单词卡片
  Widget _buildWordCard(Word word) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          word.word,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(word.meaning.join('；')),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {
            // 加入生词本功能后面再加
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('已添加 "${word.word}" 到生词本')));
          },
        ),
      ),
    );
  }
}
