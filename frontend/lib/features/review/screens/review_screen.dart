import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/word_model.dart';
import '../../../services/word_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final WordService _wordService = WordService();
  static const _bg = Color(0xFFF7F8FA);
  static const _blue = Color(0xFF4F7CFF);
  static const _batchSize = 10;
  static const _fallback = ['短暂的；瞬息的', '雄辩的；有说服力的', '意外发现珍奇事物的能力；机缘巧合', '有弹性的；能恢复的；适应力强的', '坚持不懈的精神', '突然的灵感', '偶然的机会', '丰富的；充裕的', '普通的；平凡的', '罕见的；稀有的'];

  List<Word> _queue = [];
  final List<Word> _mastered = [];
  List<String> _options = [];
  int? _correctIndex;
  int? _selectedIndex;
  int _answeredCount = 0;
  int _correctCount = 0;
  bool _loading = true;
  bool _answered = false;
  bool _isCorrect = false;

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
    final primarySegment = segments.isNotEmpty ? segments.first : normalized;

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
    _loadReviewWords();
  }

  Word get _currentWord => _queue.first;
  int get _totalCount => _queue.length + _mastered.length;
  double get _progress => _totalCount == 0 ? 0 : _mastered.length / _totalCount;

  void _exitToHome() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    context.go('/');
  }

  Future<void> _loadReviewWords() async {
    setState(() => _loading = true);
    try {
      final result = await _wordService.getDailyWords();
      if (!mounted) return;
      setState(() {
        _queue = List<Word>.from(result.reviewWords.take(_batchSize));
        _mastered.clear();
        _options = [];
        _correctIndex = null;
        _selectedIndex = null;
        _answeredCount = 0;
        _correctCount = 0;
        _answered = false;
        _isCorrect = false;
        if (_queue.isNotEmpty) _prepareOptions();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prepareOptions() {
    final correct = _currentWord.meaning.isNotEmpty ? _currentWord.meaning.first : '（暂无释义）';
    final pool = <String>[];
    for (final w in [..._queue.skip(1), ..._mastered]) {
      if (w.id != _currentWord.id && w.meaning.isNotEmpty) pool.add(w.meaning.first);
    }
    pool.shuffle();
    final distractors = <String>[];
    for (final item in pool) {
      if (item != correct && !distractors.contains(item)) distractors.add(item);
      if (distractors.length >= 3) break;
    }
    var i = 0;
    while (distractors.length < 3) {
      final item = _fallback[i % _fallback.length];
      if (item != correct && !distractors.contains(item)) distractors.add(item);
      i++;
    }
    _options = [correct, ...distractors.take(3)]..shuffle();
    _correctIndex = _options.indexOf(correct);
  }

  void _onSelectAnswer(int index) {
    if (_answered) return;
    final ok = index == _correctIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _isCorrect = ok;
      _answeredCount++;
      if (ok) _correctCount++;
    });
    _submitReviewResult(ok);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _queue.isEmpty) return;
      final word = _queue.removeAt(0);
      if (_isCorrect) {
        _mastered.add(word);
      } else {
        _queue.add(word);
      }
      if (_queue.isEmpty) {
        _showBatchFinishedDialog();
        return;
      }
      setState(() {
        _selectedIndex = null;
        _answered = false;
        _isCorrect = false;
        _prepareOptions();
      });
    });
  }

  Future<void> _submitReviewResult(bool isCorrect) async {
    try {
      await _wordService.submitLearnResult(wordId: _currentWord.id, isCorrect: isCorrect, stage: _currentWord.stage ?? 3);
    } catch (_) {}
  }

  void _showBatchFinishedDialog() {
    final accuracy = _answeredCount == 0 ? 0 : (_correctCount / _answeredCount * 100).round();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('本轮复习完成', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.emoji_events, size: 64, color: Color(0xFFFF9F43)),
          const SizedBox(height: 16),
          Text('正确率 $accuracy%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _blue)),
          const SizedBox(height: 8),
          Text('本轮已掌握 ${_mastered.length} / $_totalCount 个单词', style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text('总答题 $_answeredCount 次，答对 $_correctCount 次', style: const TextStyle(color: Color(0xFF6B7280))),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.of(d).pop(); _exitToHome(); }, child: const Text('休息一下')),
          FilledButton(
            onPressed: () async { Navigator.of(d).pop(); await _loadReviewWords(); },
            style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('继续复习'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator()));
    }
    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('复习'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(onPressed: _exitToHome, icon: const Icon(Icons.arrow_back_ios_new)),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF6BCB77)),
            const SizedBox(height: 16),
            const Text('暂无需要复习的单词', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text('继续学习新单词，积累复习内容', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 32),
            FilledButton(onPressed: _exitToHome, style: FilledButton.styleFrom(backgroundColor: _blue), child: const Text('返回首页')),
          ]),
        ),
      );
    }

    final word = _currentWord;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
          child: Column(children: [
            Row(children: [
              IconButton(onPressed: _exitToHome, icon: const Icon(Icons.arrow_back_ios_new, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
              const Expanded(child: Text('复习', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
              const SizedBox(width: 40),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('已掌握 ${_mastered.length} 个', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              Text('待掌握 ${_queue.length} 个', style: TextStyle(fontSize: 12, color: _mastered.isNotEmpty ? const Color(0xFF6BCB77) : const Color(0xFF6B7280))),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _progress, minHeight: 6, backgroundColor: const Color(0xFFE5E7EB), valueColor: const AlwaysStoppedAnimation<Color>(_blue))),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))]),
                child: Column(children: [
                  Text(word.word, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 12),
                  Text(word.phonetic, style: const TextStyle(fontSize: 16, color: Color(0xFF9CA3AF))),
                ]),
              ),
              const SizedBox(height: 32),
              const Text('请选择正确的释义', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              const SizedBox(height: 24),
              ...List.generate(_options.length, (index) {
                final option = _options[index];
                final displayOption = _formatOptionMeaning(option);
                final isSelected = _selectedIndex == index;
                final isCorrectAnswer = index == _correctIndex;
                Color? bgColor;
                var borderColor = const Color(0xFFE5E7EB);
                var textColor = const Color(0xFF1F2937);
                if (_answered) {
                  if (isCorrectAnswer) {
                    bgColor = const Color(0xFFE8F8EC);
                    borderColor = const Color(0xFF6BCB77);
                    textColor = const Color(0xFF2E7D32);
                  } else if (isSelected) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: bgColor ?? Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: _answered && (isCorrectAnswer || isSelected) ? 2 : 1)),
                      child: Row(children: [
                        Expanded(child: Text(displayOption, style: TextStyle(fontSize: 16, color: textColor, height: 1.4))),
                        if (_answered && isCorrectAnswer) const Icon(Icons.check_circle, color: Color(0xFF6BCB77), size: 24),
                        if (_answered && isSelected && !isCorrectAnswer) const Icon(Icons.cancel, color: Color(0xFFEF5350), size: 24),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('当前剩余 ${_queue.length} 个未掌握单词', style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
