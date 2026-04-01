// frontend/lib/features/study/screens/study_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/word_service.dart';
import '../../../models/word_model.dart';
import '../../../core/network/api_exception.dart';

/// 新词学习：交叉学习模式
/// 每个单词需要完成3轮（选义→例句→认词），但单词会交叉出现
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final WordService _wordService = WordService();

  static const _headerBlue = Color(0xFF5B86F8);
  static const _pageBg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF1A1C1E);

  List<Word> _dailyWords = [];

  /// 学习队列：每个元素是 (单词索引, 当前轮次 0-2)
  /// 初始时每个单词添加一次（轮次0）
  /// 每次完成后，如果轮次<2，则将 (单词索引, 轮次+1) 添加到队列末尾
  List<(int, int)> _learningQueue = [];

  /// 当前正在学习的 (单词索引, 轮次)
  int _currentWordIndex = 0;
  int _currentRound = 0; // 0:选义, 1:例句, 2:认词

  /// 每个单词的完成情况：true表示已完成3轮
  List<bool> _wordCompleted = [];

  bool _isLoading = true;
  bool _busy = false;
  bool _starred = false;

  /// 步骤1：四选一
  List<String> _mcqOptions = [];
  int? _correctMcqIndex;
  int? _selectedMcqIndex;

  static const List<String> _fallbackDistractors = [
    '短暂的；瞬息的',
    '雄辩的；有说服力的',
    '意外发现珍奇事物的能力；机缘巧合',
    '有弹性的；能恢复的；适应力强的',
  ];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Word get _word => _dailyWords[_currentWordIndex];

  /// 熟练度：轮次 0→步骤1，轮次1→步骤2，轮次2→步骤3
  int get _proficiency => _currentRound + 1;

  double get _headerProgress {
    if (_dailyWords.isEmpty) return 0;
    int totalSteps = _dailyWords.length * 3; // 每个单词3轮
    int completedSteps = 0;
    for (int i = 0; i < _dailyWords.length; i++) {
      if (_wordCompleted[i]) {
        completedSteps += 3;
      } else {
        // 当前未完成的单词，计算已完成轮次
        if (i == _currentWordIndex) {
          completedSteps += _currentRound;
        }
      }
    }
    return (completedSteps / totalSteps).clamp(0.0, 1.0);
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    try {
      final result = await _wordService.getDailyWords();
      setState(() {
        _dailyWords = result.newWords;
        _wordCompleted = List.filled(_dailyWords.length, false);

        // 初始化学习队列：每个单词添加一次（轮次0）
        _learningQueue = [];
        for (int i = 0; i < _dailyWords.length; i++) {
          _learningQueue.add((i, 0));
        }
        // 随机打乱队列顺序，让单词交叉出现
        _learningQueue.shuffle(Random());

        if (_learningQueue.isNotEmpty) {
          final next = _learningQueue.removeAt(0);
          _currentWordIndex = next.$1;
          _currentRound = next.$2;
          _prepareMcqForCurrentWord();
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

  void _prepareMcqForCurrentWord() {
    final w = _word;
    final correct = w.meaning.isNotEmpty ? w.meaning.first : '（暂无释义）';
    final pool = <String>[];
    for (final o in _dailyWords) {
      if (o.id != w.id && o.meaning.isNotEmpty) {
        pool.add(o.meaning.first);
      }
    }
    pool.shuffle(Random(w.id));
    final distractors = <String>[];
    for (final p in pool) {
      if (p != correct && !distractors.contains(p)) distractors.add(p);
      if (distractors.length >= 3) break;
    }
    var fb = 0;
    while (distractors.length < 3) {
      final d = _fallbackDistractors[fb % _fallbackDistractors.length];
      if (d != correct && !distractors.contains(d)) distractors.add(d);
      fb++;
    }
    final opts = [correct, ...distractors.take(3)];
    opts.shuffle(Random(w.id + 7));
    _mcqOptions = opts;
    _correctMcqIndex = opts.indexOf(correct);
    _selectedMcqIndex = null;
  }

  void _onSelectMcq(int i) {
    if (_busy || _currentRound != 0) return;
    setState(() => _selectedMcqIndex = i);
  }

  void _onMcqContinue() {
    if (_selectedMcqIndex == null || _correctMcqIndex == null) return;
    if (_selectedMcqIndex != _correctMcqIndex) {
      setState(() {
        _selectedMcqIndex = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('选择错误，请再试一次'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _completeCurrentRound();
  }

  void _onStep2Know(bool know) {
    if (_busy) return;
    if (know) {
      _completeCurrentRound();
    } else {
      _resetCurrentWord();
    }
  }

  void _onStep3Know(bool know) async {
    if (_busy) return;
    if (!know) {
      _resetCurrentWord();
      return;
    }
    _completeCurrentRound();
  }

  /// 完成当前轮次
  void _completeCurrentRound() {
    setState(() => _busy = true);

    // 检查是否是最后一轮（轮次2）
    final bool isLastRound = (_currentRound == 2);

    if (isLastRound) {
      // 标记单词已完成
      _wordCompleted[_currentWordIndex] = true;
      // 上报学习结果
      _submitWordResult(_currentWordIndex);
    } else {
      // 不是最后一轮，将下一个轮次加入队列末尾
      _learningQueue.add((_currentWordIndex, _currentRound + 1));
    }

    // 加载下一个单词
    _loadNextWord();
  }

  Future<void> _submitWordResult(int wordIndex) async {
    try {
      await _wordService.submitLearnResult(
        wordId: _dailyWords[wordIndex].id,
        isCorrect: true,
      );
    } catch (_) {
      // 静默处理错误，不影响学习流程
    }
  }

  /// 加载下一个单词
  void _loadNextWord() {
    if (_learningQueue.isEmpty) {
      // 所有单词都完成了
      _finishStudy();
      return;
    }

    // 从队列头部取出下一个
    final next = _learningQueue.removeAt(0);
    setState(() {
      _currentWordIndex = next.$1;
      _currentRound = next.$2;
      _selectedMcqIndex = null;
      _busy = false;
    });

    // 根据轮次准备不同的内容
    if (_currentRound == 0) {
      _prepareMcqForCurrentWord();
    }
  }

  void _resetCurrentWord() {
    // 将当前单词的所有未完成轮次重新加入队列
    // 从当前轮次开始重新学习
    _learningQueue.insert(0, (_currentWordIndex, _currentRound));
    _loadNextWord();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('继续加油，再试一次！'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _finishStudy() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 恭喜完成今日学习任务！'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  String _exampleLine(Word w) {
    if (w.example != null && w.example!.isNotEmpty) {
      return w.example!.first;
    }
    return 'Try to remember the word "${w.word}" in context.';
  }

  /// 获取当前学习进度文本
  String _getProgressText() {
    int completed = 0;
    for (int i = 0; i < _dailyWords.length; i++) {
      if (_wordCompleted[i]) {
        completed++;
      }
    }
    return '${completed + (_currentRound > 0 ? 1 : 0)}/${_dailyWords.length} 单词';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _pageBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dailyWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('今日学习')),
        body: const Center(child: Text('今日没有新单词，去复习吧！')),
      );
    }

    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          _buildHeader(context, top),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _currentRound == 0
                  ? _buildStep1()
                  : _currentRound == 1
                  ? _buildStep2()
                  : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double top) {
    final totalWords = _dailyWords.length;
    final completedCount = _wordCompleted.where((c) => c).length;
    final currentProgress = completedCount + (_currentRound > 0 ? 1 : 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4, top + 4, 8, 12),
      decoration: const BoxDecoration(
        color: _headerBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
              ),
              Expanded(
                child: Text(
                  '学习中 ($currentProgress/$totalWords)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _starred = !_starred),
                icon: Icon(
                  _starred ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _headerProgress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '步骤 ${_currentRound + 1}/3',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final w = _word;
    final sel = _selectedMcqIndex;
    final correct = _correctMcqIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '选择正确的中文意思',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    w.word,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A8C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.volume_up_rounded,
                    color: _headerBlue.withValues(alpha: 0.9),
                    size: 26,
                  ),
                ],
              ),
              if (w.phonetic.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  w.phonetic,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(_mcqOptions.length, (i) {
          final text = _mcqOptions[i];
          final isSel = sel == i;
          final isCorrect = correct == i;
          Color? bg;
          Color border = const Color(0xFFE0E0E0);
          if (sel != null) {
            if (isCorrect) {
              bg = const Color(0xFFE8F8EC);
              border = const Color(0xFF66CC77);
            } else if (isSel && !isCorrect) {
              bg = const Color(0xFFFFEBEE);
              border = const Color(0xFFE57373);
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: bg ?? Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _onSelectMcq(i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: border,
                      width: sel != null && (isSel || isCorrect) ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 15,
                            color: sel != null && isCorrect
                                ? const Color(0xFF2E7D32)
                                : (isSel && !isCorrect
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFF333333)),
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (sel != null && isCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF66CC77),
                          size: 22,
                        ),
                      if (sel != null && isSel && !isCorrect)
                        const Icon(
                          Icons.cancel,
                          color: Color(0xFFE57373),
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: (sel != null && sel == correct) ? _onMcqContinue : null,
            style: FilledButton.styleFrom(
              backgroundColor: _headerBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '继续',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final w = _word;
    final line = _exampleLine(w);
    final lw = w.word.toLowerCase();
    final lowLine = line.toLowerCase();
    final idx = lowLine.indexOf(lw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '看例句，你认识这个词吗？',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    w.word,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.volume_up_rounded, color: _headerBlue, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: idx >= 0
                    ? Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF333333),
                          ),
                          children: [
                            TextSpan(text: line.substring(0, idx)),
                            TextSpan(
                              text: line.substring(idx, idx + w.word.length),
                              style: const TextStyle(
                                color: _headerBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: line.substring(idx + w.word.length)),
                          ],
                        ),
                      )
                    : Text(
                        line,
                        style: const TextStyle(fontSize: 15, height: 1.45),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _onStep2Know(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFD0D0D0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '不认识',
                  style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _onStep2Know(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _headerBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '认识',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final w = _word;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '你还记得这个词的意思吗？',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                w.word,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.volume_up_rounded, color: _headerBlue, size: 28),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _onStep3Know(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFD0D0D0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '不认识',
                  style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _onStep3Know(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _headerBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '认识',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
