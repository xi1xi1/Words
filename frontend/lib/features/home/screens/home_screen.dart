import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/word_service.dart';
import '../../../models/word_model.dart';
import '../../../core/network/api_exception.dart';
import '../../study/screens/study_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeContent();
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final WordService _wordService = WordService();
  bool _loading = true;
  List<Word> _newWords = [];
  List<Word> _reviewWords = [];

  static const _bg = Color(0xFFF7F8FA);
  static const _blue = Color(0xFF4A74F5);
  static const _navy = Color(0xFF1A1C1E);
  static const _muted = Color(0xFF8E9297);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _wordService.getDailyWords();
      setState(() {
        _newWords = r.newWords;
        _reviewWords = r.reviewWords;
      });
    } on ApiException catch (_) {
      /* 保持空列表 */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  Word? get _featured {
    if (_newWords.isNotEmpty) return _newWords.first;
    if (_reviewWords.isNotEmpty) return _reviewWords.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final featured = _featured;
    final todayN = _newWords.isEmpty ? 50 : _newWords.length;
    final reviewN = _reviewWords.isEmpty ? 128 : _reviewWords.length;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '背',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(fontSize: 13, color: _muted),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '词汇学习者',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '连续学习',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '7天',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      iconBg: const Color(0xFFE8EEFD),
                      icon: Icons.menu_book_rounded,
                      iconColor: _blue,
                      value: '$todayN',
                      label: '今日学习',
                      action: '开始学习 >',
                      actionColor: _blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      iconBg: const Color(0xFFFFF2E6),
                      icon: Icons.autorenew_rounded,
                      iconColor: Color(0xFFFF9F43),
                      value: '$reviewN',
                      label: '待复习',
                      action: '立即复习 >',
                      actionColor: Color(0xFFFF9F43),
                      onTap: () {
                        if (reviewN > 0) {
                          context.push('/review');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('暂无需要复习的单词，去学习新单词吧！'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Icon(Icons.star_outline_rounded, color: _blue, size: 22),
                  const SizedBox(width: 6),
                  const Text(
                    '今日推荐',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (featured == null)
                _placeholderDemoCard()
              else
                _featuredCard(featured),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String action,
    required Color actionColor,
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
              const SizedBox(height: 10),
              Text(
                action,
                style: TextStyle(
                  fontSize: 13,
                  color: actionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderDemoCard() {
    return _featuredCard(
      Word(
        id: 0,
        word: 'serendipity',
        phonetic: '/ˌserənˈdɪpəti/',
        meaning: const ['意外发现珍奇事物的能力；机缘巧合'],
        example: const [
          'The discovery of penicillin was a case of serendipity.',
          '青霉素的发现是一个意外发现的例子。',
        ],
      ),
      isPlaceholder: true,
    );
  }

  Widget _featuredCard(Word word, {bool isPlaceholder = false}) {
    final ex = word.example;
    final en = (ex != null && ex.isNotEmpty) ? ex.first : '';
    final zh = (ex != null && ex.length > 1) ? ex[1] : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        word.word,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: _blue,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '+ 生词本',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ),
            ],
          ),
          if (word.phonetic.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              word.phonetic,
              style: const TextStyle(fontSize: 14, color: _muted),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'n. 名词',
              style: TextStyle(
                fontSize: 12,
                color: _blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            word.meaning.join('；'),
            style: const TextStyle(fontSize: 15, height: 1.4, color: _navy),
          ),
          if (en.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _richExample(en, word.word),
                  if (zh.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      zh,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '查看详情 >',
            style: TextStyle(
              fontSize: 14,
              color: _blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isPlaceholder)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '（登录并拉取数据后显示真实推荐词）',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _richExample(String sentence, String w) {
    final lower = sentence.toLowerCase();
    final lw = w.toLowerCase();
    final i = lower.indexOf(lw);
    if (i < 0) {
      return Text(
        sentence,
        style: const TextStyle(fontSize: 14, height: 1.4, color: _navy),
      );
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.4, color: _navy),
        children: [
          TextSpan(text: sentence.substring(0, i)),
          TextSpan(
            text: sentence.substring(i, i + w.length),
            style: const TextStyle(color: _blue, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: sentence.substring(i + w.length)),
        ],
      ),
    );
  }
}
