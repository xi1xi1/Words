// frontend/lib/features/review/screens/review_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/word_service.dart';
import '../../../models/word_model.dart';
import '../../../core/network/api_exception.dart';

/// 复习页面
/// 展示需要复习的单词，用户选择正确释义
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final WordService _wordService = WordService();

  static const _headerBlue = Color(0xFF5B86F8);
  static const _pageBg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF1A1C1E);

  List<Word> _reviewWords = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _answeredCount = 0;

  bool _isLoading = true;
  bool _answered = false;
  bool _isCorrect = false;
  int? _selectedIndex;

  List<String> _options = [];
  int? _correctIndex;

  static const List<String> _fallbackDistractors = [
    '短暂的；瞬息的',
    '雄辩的；有说服力的',
    '意外发现珍奇事物的能力；机缘巧合',
    '有弹性的；能恢复的；适应力强的',
    '坚持不懈的精神',
    '突然的灵感',
    '偶然的机会',
    '丰富的；充裕的',
    '普通的；平凡的',
    '罕见的；稀有的',
  ];

  @override
  void initState() {
    super.initState();
    _loadReviewWords();
  }

  Word get _currentWord => _reviewWords[_currentIndex];

  double get _progress {
    if (_reviewWords.isEmpty) return 0;
    return (_currentIndex + 1) / _reviewWords.length;
  }

  Future<void> _loadReviewWords() async {
    setState(() => _isLoading = true);
    try {
      final result = await _wordService.getDailyWords();
      setState(() {
        // 使用复习单词列表
        _reviewWords = result.reviewWords;
        if (_reviewWords.isNotEmpty) {
          _prepareOptions();
        }
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

  void _prepareOptions() {
    final word = _currentWord;
    final correct = word.meaning.isNotEmpty ? word.meaning.first : '（暂无释义）';

    // 收集干扰项
    final pool = <String>[];
    for (final w in _reviewWords) {
      if (w.id != word.id && w.meaning.isNotEmpty) {
        pool.add(w.meaning.first);
      }
    }

    // 从单词表中收集干扰项
    pool.shuffle();
    final distractors = <String>[];
    for (final p in pool) {
      if (p != correct && !distractors.contains(p)) {
        distractors.add(p);
      }
      if (distractors.length >= 3) break;
    }

    // 如果干扰项不够，使用备用干扰项
    var fb = 0;
    while (distractors.length < 3) {
      final d = _fallbackDistractors[fb % _fallbackDistractors.length];
      if (d != correct && !distractors.contains(d)) {
        distractors.add(d);
      }
      fb++;
    }

    // 构建选项列表：正确 + 3个干扰项
    final opts = [correct, ...distractors.take(3)];
    opts.shuffle();
    _options = opts;
    _correctIndex = opts.indexOf(correct);
  }

  void _onSelectAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      _isCorrect = (index == _correctIndex);
      if (_isCorrect) {
        _correctCount++;
      }
      _answeredCount++;
    });

    // 上报学习结果
    _submitReviewResult(_isCorrect);

    // 1.5秒后自动进入下一题
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentIndex + 1 < _reviewWords.length) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _selectedIndex = null;
          _prepareOptions();
        });
      } else {
        _showResultDialog();
      }
    });
  }

  Future<void> _submitReviewResult(bool isCorrect) async {
    try {
      await _wordService.submitLearnResult(
        wordId: _currentWord.id,
        isCorrect: isCorrect,
        stage: 3,
      );
    } catch (_) {
      // 静默处理错误
    }
  }

  void _showResultDialog() {
    final accuracy = _answeredCount > 0
        ? (_correctCount / _answeredCount * 100).round()
        : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '复习完成',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Color(0xFFFF9F43)),
            const SizedBox(height: 16),
            Text(
              '正确率 $accuracy%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F7CFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '共复习 $_answeredCount 个单词',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            Text(
              '正确 $_correctCount 个',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回上一页
            },
            child: const Text('返回首页'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              // 重新开始复习
              setState(() {
                _currentIndex = 0;
                _correctCount = 0;
                _answeredCount = 0;
                _answered = false;
                _selectedIndex = null;
                _prepareOptions();
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F7CFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('再复习一次'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _pageBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_reviewWords.isEmpty) {
      return Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: const Text('复习'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Color(0xFF6BCB77),
              ),
              const SizedBox(height: 16),
              const Text(
                '暂无需要复习的单词',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '继续学习新单词，积累复习内容',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7CFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      );
    }

    final top = MediaQuery.paddingOf(context).top;
    final word = _currentWord;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          // 头部
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '复习',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '已完成 $_answeredCount 题',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '正确 $_correctCount 题',
                      style: TextStyle(
                        fontSize: 12,
                        color: _correctCount > 0
                            ? const Color(0xFF6BCB77)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4F7CFF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 单词卡片
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: Column(
                children: [
                  // 单词展示卡片
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          word.phonetic,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                // 播放发音（可后续接入TTS）
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('发音功能开发中'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                size: 28,
                                color: Color(0xFF4F7CFF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 题目
                  const Text(
                    '请选择正确的释义',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 选项列表
                  ...List.generate(_options.length, (index) {
                    final option = _options[index];
                    final isSelected = _selectedIndex == index;
                    final isCorrectAnswer = index == _correctIndex;

                    Color? bgColor;
                    Color borderColor = const Color(0xFFE5E7EB);
                    Color textColor = const Color(0xFF1F2937);

                    if (_answered) {
                      if (isCorrectAnswer) {
                        bgColor = const Color(0xFFE8F8EC);
                        borderColor = const Color(0xFF6BCB77);
                        textColor = const Color(0xFF2E7D32);
                      } else if (isSelected && !isCorrectAnswer) {
                        bgColor = const Color(0xFFFFEBEE);
                        borderColor = const Color(0xFFEF5350);
                        textColor = const Color(0xFFC62828);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: _answered ? null : () => _onSelectAnswer(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor ?? Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width:
                                  _answered && (isCorrectAnswer || isSelected)
                                  ? 2
                                  : 1,
                            ),
                            boxShadow: [
                              if (!_answered)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _answered && isCorrectAnswer
                                      ? const Color(0xFF6BCB77).withOpacity(0.1)
                                      : (_answered &&
                                                isSelected &&
                                                !isCorrectAnswer
                                            ? const Color(
                                                0xFFEF5350,
                                              ).withOpacity(0.1)
                                            : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _answered && isCorrectAnswer
                                          ? const Color(0xFF2E7D32)
                                          : (_answered &&
                                                    isSelected &&
                                                    !isCorrectAnswer
                                                ? const Color(0xFFC62828)
                                                : const Color(0xFF6B7280)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              if (_answered && isCorrectAnswer)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF6BCB77),
                                  size: 24,
                                ),
                              if (_answered && isSelected && !isCorrectAnswer)
                                const Icon(
                                  Icons.cancel,
                                  color: Color(0xFFEF5350),
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // 当前进度提示
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '${_currentIndex + 1} / ${_reviewWords.length} 题',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
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
}
