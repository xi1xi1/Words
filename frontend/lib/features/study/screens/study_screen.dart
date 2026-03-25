// frontend/lib/features/study/screens/study_screen.dart
import 'package:flutter/material.dart';
import '../../../services/word_service.dart';
import '../../../models/word_model.dart';
import '../../../core/network/api_exception.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final WordService _wordService = WordService();

  List<Word> _dailyWords = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showMeaning = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);

    try {
      final result = await _wordService.getDailyWords();
      setState(() {
        _dailyWords = result.newWords;
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

  Future<void> _submitAnswer(bool isCorrect) async {
    final currentWord = _dailyWords[_currentIndex];

    setState(() {
      _feedback = isCorrect ? '✅ 回答正确！' : '❌ 回答错误！';
      _showMeaning = true;
    });

    try {
      await _wordService.submitLearnResult(
        wordId: currentWord.id,
        isCorrect: isCorrect,
      );

      // 处理学习结果
    } catch (e) {
      // 即使接口失败，也继续学习流程
    }

    // 2秒后自动进入下一个单词
    await Future.delayed(const Duration(seconds: 2));

    if (_currentIndex + 1 < _dailyWords.length) {
      setState(() {
        _currentIndex++;
        _showMeaning = false;
        _feedback = null;
      });
    } else {
      // 完成所有单词
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('恭喜完成今日学习任务！'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_dailyWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('今日学习')),
        body: const Center(child: Text('今日没有新单词，去复习吧！')),
      );
    }

    final currentWord = _dailyWords[_currentIndex];
    final progress = (_currentIndex + 1) / _dailyWords.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('标准背词'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4F7CFF)),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 进度显示
            Text(
              '${_currentIndex + 1} / ${_dailyWords.length}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // 单词卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    currentWord.word,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentWord.phonetic.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentWord.phonetic,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_showMeaning) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    ...currentWord.meaning.map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(m, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    if (currentWord.example != null &&
                        currentWord.example!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        currentWord.example!.first,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 反馈信息
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _feedback!,
                  style: TextStyle(
                    fontSize: 16,
                    color: _feedback!.contains('正确')
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 操作按钮
            if (!_showMeaning)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitAnswer(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('不认识'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitAnswer(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('认识'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
