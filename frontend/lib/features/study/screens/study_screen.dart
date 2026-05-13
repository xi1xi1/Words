// frontend/lib/features/study/screens/study_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/word_service.dart';
import '../../../models/word_model.dart';
import '../../../core/network/api_exception.dart';

class StudyScreen extends StatefulWidget {
  final WordService? wordService;

  const StudyScreen({
    super.key,
    this.wordService,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final WordService _wordService;

  static const _headerBlue = Color(0xFF5B86F8);
  static const _pageBg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF1A1C1E);
  static const _green = Color(0xFF4CAF50);

  static const int _batchSize = 10;

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
  int _batchCompletedCount = 0;
  int _batchTargetCount = _batchSize;

  static const List<String> _fallbackDistractors = [
    '短暂的；瞬息的',
    '雄辩的；有说服力的',
    '意外发现珍奇事物的能力',
    '有弹性的；能恢复的',
  ];

  String _formatOptionMeaning(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'\\+u0026', caseSensitive: false), '/')
        .replaceAll(RegExp(r'u0026', caseSensitive: false), '/')
        .replaceAll(RegExp(r'\s*/\s*'), '/');
    final normalized = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return text;

    final segments = normalized
        .split(RegExp(r'(?=(?:^|\s)[a-zA-Z]+\.)'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    // 换行或空格隔开的「vt. … vi. …」会被切成多段；不能只取第一段否则只剩「vt.&」
    final primarySegment = segments.length > 1
        ? segments.join(' ')
        : (segments.isNotEmpty ? segments.first : normalized);

    final match = RegExp(r'^(?<prefix>[a-zA-Z]+\.)\s*(?<rest>.+)$').firstMatch(primarySegment);
    final prefix = match?.namedGroup('prefix');
    final rest = (match?.namedGroup('rest') ?? primarySegment).trim();
    final items = rest
        .split(RegExp(r'[,，；;]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (items.length <= 2) return primarySegment;

    final truncated = items.take(2).join(',');
    return prefix == null ? truncated : '$prefix$truncated';
  }

  @override
  void initState() {
    super.initState();
    _wordService = widget.wordService ?? WordService();
    _loadAndStartStudy();
  }

  double get _headerProgress {
    if (_batchTargetCount == 0) return 0;
    return (_batchCompletedCount / _batchTargetCount).clamp(0.0, 1.0);
  }

  Future<void> _startNextBatch() async {
    _batchCompletedCount = 0;
    _batchTargetCount = _batchSize;
    await _loadAndStartStudy();
  }

  void _exitToHome() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    context.go('/');
  }

  void _handleClose() {
    if (_batchCompletedCount > 0) {
      _showBatchSettlementDialog(completed: false);
      return;
    }
    _exitToHome();
  }

  void _showBatchSettlementDialog({required bool completed}) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final title = completed ? '本轮学习完成' : '先休息一下';
    final subtitle = completed
        ? '本轮已完成 $_batchCompletedCount / $_batchTargetCount 个单词'
        : '当前进度 $_batchCompletedCount / $_batchTargetCount';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completed ? Icons.celebration : Icons.hotel_rounded,
              color: _headerBlue,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _exitToHome();
            },
            child: const Text('休息一下'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _startNextBatch();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _headerBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('继续学习'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAndStartStudy() async {
    setState(() => _isLoading = true);
    try {
      final result = await _wordService.getDailyWords();
      if (!mounted) return;

      final learningWords = result.newWords;
      if (learningWords.isEmpty) {
        setState(() {
          _currentWord = null;
          _isLoading = false;
        });
        return;
      }

      final words = [...learningWords]..shuffle();
      final first = words.first;
      final batchTotal = learningWords.length;

      setState(() {
        _batchTargetCount = batchTotal;
        _progress = LearnProgress(
          completedCount: _batchCompletedCount,
          totalCount: _batchTargetCount,
        );
        _currentWord = first;
        _prepareForStage(first.stage ?? 1);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      _exitToHome();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNextWordFromQueue() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await _wordService.getDailyWords();
      if (!mounted) return;

      final learningWords = result.newWords;

      if (learningWords.isEmpty) {
        setState(() => _isSubmitting = false);
        _showBatchSettlementDialog(completed: _batchCompletedCount >= _batchTargetCount);
        return;
      }

      final words = [...learningWords]..shuffle();
      final next = words.first;

      setState(() {
        _currentWord = next;
        _progress = LearnProgress(
          completedCount: _batchCompletedCount,
          totalCount: _batchTargetCount,
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

      if (isCorrect && _currentStage == 3) {
        _batchCompletedCount++;
      }

      setState(() {
        _progress = LearnProgress(
          completedCount: _batchCompletedCount,
          totalCount: _batchTargetCount,
        );
      });

      if (_batchCompletedCount >= _batchTargetCount) {
        _showBatchSettlementDialog(completed: true);
        return;
      }

      if (result.nextWord == null) {
        await _loadNextWordFromQueue();
        return;
      }

      setState(() {
        _currentWord = result.nextWord;
        _progress = LearnProgress(
          completedCount: _batchCompletedCount,
          totalCount: _batchTargetCount,
        );
        _prepareForStage(_currentWord!.stage ?? 1);
        _isSubmitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      _exitToHome();
    }
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
                onPressed: _exitToHome,
                child: const Text('返回首页'),
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
                onPressed: _handleClose,
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
    final displayText = _formatOptionMeaning(text);
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
                    displayText,
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
