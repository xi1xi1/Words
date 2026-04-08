// frontend/lib/features/study/screens/study_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  static const _headerBlue = Color(0xFF5B86F8);
  static const _pageBg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF1A1C1E);
  static const _green = Color(0xFF4CAF50);

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showResult = false;
  bool _lastAnswerCorrect = false;

  int? _selectedOptionIndex;
  List<String> _options = [];
  int _correctOptionIndex = 0;

  Word? _currentWord;
  int _currentStage = 1;
  LearnProgress? _progress;

  static const List<String> _fallbackDistractors = [
    '短暂的；瞬息的',
    '雄辩的；有说服力的',
    '意外发现珍奇事物的能力',
    '有弹性的；能恢复的',
  ];

  @override
  void initState() {
    super.initState();
    _loadAndStartStudy();
  }

  double get _headerProgress {
    if (_progress == null || _progress!.totalCount == 0) return 0;
    return _progress!.progress.clamp(0.0, 1.0);
  }

  Future<void> _loadAndStartStudy() async {
    setState(() => _isLoading = true);
    try {
      final result = await _wordService.getDailyWords();
      if (!mounted) return;

      final allWords = [...result.newWords, ...result.reviewWords];
      if (allWords.isEmpty) {
        setState(() {
          _currentWord = null;
          _isLoading = false;
        });
        return;
      }

      allWords.shuffle();
      final first = allWords.first;

      setState(() {
        _progress = LearnProgress(
          completedCount: 0,
          totalCount: result.total > 0 ? result.total : allWords.length,
        );
        _currentWord = first;
        _prepareForStage(first.stage ?? 1);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNextWordFromQueue() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await _wordService.getDailyWords();
      if (!mounted) return;

      final allWords = [...result.newWords, ...result.reviewWords];

      if (allWords.isEmpty) {
        setState(() => _isSubmitting = false);
        final completed = _progress?.completedCount ?? 0;
        final total = _progress?.totalCount ?? 0;
        if (total > 0 && completed >= total) {
          _finishStudy();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('今日单词已学完'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      allWords.shuffle();
      final next = allWords.first;

      setState(() {
        _currentWord = next;
        _progress = LearnProgress(
          completedCount: _progress?.completedCount ?? 0,
          totalCount: result.total > 0 ? result.total : allWords.length,
        );
        _prepareForStage(next.stage ?? 1);
        _isSubmitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  void _prepareForStage(int stage) {
    _currentStage = stage;
    _showResult = false;
    _selectedOptionIndex = null;
    _lastAnswerCorrect = false;

    if (stage == 1) {
      _prepareOptions();
    }
  }

  void _prepareOptions() {
    final word = _currentWord;
    if (word == null) return;

    if (word.options != null && word.options!.isNotEmpty) {
      _options = List<String>.from(word.options!);
      final correct = word.meaning.isNotEmpty ? word.meaning.first : '（暂无释义）';
      _correctOptionIndex = _options.indexOf(correct);
      if (_correctOptionIndex >= 0) return;
    }

    final correct = word.meaning.isNotEmpty ? word.meaning.first : '（暂无释义）';
    _correctOptionIndex = 0;

    final pool = <String>[];
    for (final o in (word.meaning.length > 1 ? word.meaning.skip(1).toList() : <String>[])) {
      pool.add(o);
    }

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

    _options = [correct, ...distractors.take(3)];
    _options.shuffle();
    _correctOptionIndex = _options.indexOf(correct);
  }

  Future<void> _onSelectOption(int index) async {
    if (_isSubmitting || _showResult) return;
    setState(() => _selectedOptionIndex = index);

    final isCorrect = index == _correctOptionIndex;
    await _submitAnswer(isCorrect);
  }

  Future<void> _onKnow(bool know) async {
    if (_isSubmitting || _showResult) return;
    await _submitAnswer(know);
  }

  Future<void> _submitAnswer(bool isCorrect) async {
    if (_currentWord == null) return;

    setState(() {
      _isSubmitting = true;
      _showResult = true;
      _lastAnswerCorrect = isCorrect;
    });

    try {
      final result = await _wordService.submitLearnResult(
        wordId: _currentWord!.id,
        isCorrect: isCorrect,
        stage: _currentStage,
      );

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;

      setState(() {
        _progress = result.progress;
      });

      if (result.nextWord == null) {
        final completed = result.progress.completedCount;
        final total = result.progress.totalCount;

        if (total > 0 && completed >= total) {
          _finishStudy();
          return;
        }

        await _loadNextWordFromQueue();
        return;
      }

      setState(() {
        _currentWord = result.nextWord;
        _progress = result.progress;
        _prepareForStage(_currentWord!.stage ?? 1);
        _isSubmitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      context.pop();
    }
  }

  void _finishStudy() {
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: _headerBlue, size: 64),
            const SizedBox(height: 16),
            const Text(
              '恭喜完成！',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '今日已学习 ${_progress?.completedCount ?? 0} 个单词',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _headerBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('返回', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _exampleLine(Word w) {
    if (w.example != null && w.example!.isNotEmpty) {
      return w.example!.first;
    }
    return 'Try to remember the word "${w.word}" in context.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _pageBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentWord == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('今日学习')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: _green, size: 64),
              const SizedBox(height: 16),
              const Text('今日单词已全部学完！', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          _buildHeader(top),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _currentStage == 1
                  ? _buildStage1()
                  : _currentStage == 2
                      ? _buildStage2()
                      : _buildStage3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top) {
    final completed = _progress?.completedCount ?? 0;
    final total = _progress?.totalCount ?? 0;

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
                  '学习中 ($completed/$total)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48),
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
              _getStageTitle(),
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

  String _getStageTitle() {
    switch (_currentStage) {
      case 1:
        return '步骤 1/3 - 选择释义';
      case 2:
        return '步骤 2/3 - 看例句';
      case 3:
        return '步骤 3/3 - 认词';
      default:
        return '学习中';
    }
  }

  Widget _buildStage1() {
    final w = _currentWord!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '选择正确的中文意思',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _navy),
        ),
        const SizedBox(height: 20),
        _buildWordCard(w),
        const SizedBox(height: 20),
        ...List.generate(_options.length, (i) => _buildOptionButton(i, _options[i])),
      ],
    );
  }

  Widget _buildStage2() {
    final w = _currentWord!;
    final line = _exampleLine(w);
    final lw = w.word.toLowerCase();
    final idx = line.toLowerCase().indexOf(lw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '看例句，你认识这个词吗？',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _navy),
        ),
        const SizedBox(height: 20),
        _buildWordCard(w),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: idx >= 0
              ? Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF333333)),
                    children: [
                      TextSpan(text: line.substring(0, idx)),
                      TextSpan(
                        text: line.substring(idx, idx + w.word.length),
                        style: const TextStyle(color: _headerBlue, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: line.substring(idx + w.word.length)),
                    ],
                  ),
                )
              : Text(line, style: const TextStyle(fontSize: 15, height: 1.5)),
        ),
        const SizedBox(height: 28),
        _buildKnowButtons(),
      ],
    );
  }

  Widget _buildStage3() {
    final w = _currentWord!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '你还记得这个词的意思吗？',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _navy),
        ),
        const SizedBox(height: 20),
        _buildWordCard(w, large: true),
        const SizedBox(height: 28),
        _buildKnowButtons(),
      ],
    );
  }

  Widget _buildWordCard(Word w, {bool large = false}) {
    return Container(
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
                style: TextStyle(
                  fontSize: large ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D4A8C),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.volume_up_rounded,
                color: _headerBlue.withValues(alpha: 0.9),
                size: large ? 32 : 26,
              ),
            ],
          ),
          if (w.phonetic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              w.phonetic,
              style: const TextStyle(fontSize: 14, color: Color(0xFF636E72)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String text) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == _correctOptionIndex;
    final showCorrect = _showResult && isCorrect;
    final showWrong = _showResult && isSelected && !isCorrect;

    Color? bg;
    Color border = const Color(0xFFE0E0E0);
    Color textColor = const Color(0xFF333333);

    if (showCorrect) {
      bg = const Color(0xFFE8F8EC);
      border = const Color(0xFF66CC77);
      textColor = const Color(0xFF2E7D32);
    } else if (showWrong) {
      bg = const Color(0xFFFFEBEE);
      border = const Color(0xFFE57373);
      textColor = const Color(0xFFC62828);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _showResult ? null : () => _onSelectOption(index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
                width: _showResult && (showCorrect || showWrong) ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 15, color: textColor, height: 1.35),
                  ),
                ),
                if (showCorrect)
                  const Icon(Icons.check_circle, color: Color(0xFF66CC77), size: 22),
                if (showWrong)
                  const Icon(Icons.cancel, color: Color(0xFFE57373), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKnowButtons() {
    final showCorrect = _showResult && _lastAnswerCorrect;
    final showWrong = _showResult && !_lastAnswerCorrect;

    return Row(
      children: [
        Expanded(
          child: _buildKnowButton(
            label: '不认识',
            isSelected: showWrong,
            isCorrect: false,
            onTap: _showResult ? null : () => _onKnow(false),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildKnowButton(
            label: '认识',
            isSelected: showCorrect,
            isCorrect: true,
            onTap: _showResult ? null : () => _onKnow(true),
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildKnowButton({
    required String label,
    required bool isSelected,
    required bool isCorrect,
    VoidCallback? onTap,
    bool filled = false,
  }) {
    Color bg;
    Color border;
    Color textColor;

    if (isSelected) {
      if (isCorrect) {
        bg = const Color(0xFFE8F8EC);
        border = const Color(0xFF66CC77);
        textColor = const Color(0xFF2E7D32);
      } else {
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFE57373);
        textColor = const Color(0xFFC62828);
      }
    } else {
      bg = filled ? _headerBlue : Colors.white;
      border = filled ? _headerBlue : const Color(0xFFD0D0D0);
      textColor = filled ? Colors.white : const Color(0xFF333333);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected && isCorrect)
                const Icon(Icons.check_circle, color: Color(0xFF66CC77), size: 20),
              if (isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Color(0xFFE57373), size: 20),
              if (isSelected) const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
