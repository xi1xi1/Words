import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/wordbook_provider.dart';
import '../../../models/word_model.dart';
import '../../../services/word_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeContent();
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _wordService = WordService();
  bool _loading = true;
  List<Word> _newWords = [];
  List<Word> _reviewWords = [];
  int _maxNewWords = 0;
  int _maxReviewWords = 0;

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
      if (!mounted) return;
      setState(() {
        _newWords = r.newWords;
        _reviewWords = r.reviewWords;
        _maxNewWords = r.maxNewWords;
        _maxReviewWords = r.maxReviewWords;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _newWords = [];
        _reviewWords = [];
        _maxNewWords = 0;
        _maxReviewWords = 0;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleWordbook(Word word) async {
    if (word.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前是演示单词，暂不支持加入生词本')),
      );
      return;
    }
    final provider = context.read<WordbookProvider>();
    try {
      if (provider.containsWord(word.id)) {
        await provider.removeWord(word.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移出生词本')),
        );
      } else {
        await provider.addWord(word.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入生词本')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  Word? get _featured => _newWords.isNotEmpty
      ? _newWords.first
      : _reviewWords.isNotEmpty
          ? _reviewWords.first
          : null;

  @override
  Widget build(BuildContext context) {
    final featured = _featured;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final muted = isDark ? const Color(0xFF9AA3AF) : _muted;
    final exampleBg = isDark ? const Color(0xFF252A31) : const Color(0xFFF3F4F6);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 4),
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('背', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(), style: TextStyle(fontSize: 13, color: muted)),
                      const SizedBox(height: 2),
                      Text('词汇学习者', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                  child: _statCard('今日学习', '${_maxNewWords > 0 ? _maxNewWords : _newWords.length}', Icons.menu_book_rounded, _blue, () async {
                    await context.push('/study');
                    if (mounted) await _load();
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard('待复习', '${_maxReviewWords > 0 ? _maxReviewWords : _reviewWords.length}', Icons.autorenew_rounded, const Color(0xFFFF9F43), () async {
                    if (_reviewWords.isNotEmpty) {
                      await context.push('/review');
                      if (mounted) await _load();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无需要复习的单词')));
                    }
                  }),
                ),
              ]),
              const SizedBox(height: 26),
              Row(children: const [
                Icon(Icons.star_outline_rounded, color: _blue, size: 22),
                SizedBox(width: 6),
                Text('今日推荐', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _navy)),
              ]),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (featured == null)
                _featuredCard(
                  Word(
                    id: 0,
                    word: 'serendipity',
                    phonetic: '/ˌserənˈdɪpəti/',
                    meaning: const ['意外发现珍奇事物的能力；机缘巧合'],
                    example: const ['The discovery of penicillin was a case of serendipity.', '青霉素的发现是一个意外发现的例子。'],
                  ),
                  isPlaceholder: true,
                )
              else
                _featuredCard(featured),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final muted = isDark ? const Color(0xFF9AA3AF) : _muted;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: muted)),
          ]),
        ),
      ),
    );
  }

  Widget _featuredCard(Word word, {bool isPlaceholder = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final muted = isDark ? const Color(0xFF9AA3AF) : _muted;
    final exampleBg = isDark ? const Color(0xFF252A31) : const Color(0xFFF3F4F6);
    final ex = word.example;
    final en = ex != null && ex.isNotEmpty ? ex.first : '';
    final zh = ex != null && ex.length > 1 ? ex[1] : '';
    final inWordbook = context.watch<WordbookProvider>().containsWord(word.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(word.word, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface))),
          TextButton(
            onPressed: () => _toggleWordbook(word),
            child: Text(inWordbook ? '已加入' : '+ 生词本', style: TextStyle(color: inWordbook ? _blue : _muted)),
          ),
        ]),
        if (word.phonetic.isNotEmpty) Text(word.phonetic, style: TextStyle(fontSize: 14, color: muted)),
        const SizedBox(height: 10),
        Text(word.meaning.join('；'), style: TextStyle(fontSize: 15, height: 1.4, color: onSurface)),
        if (en.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: exampleBg, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _richExample(en, word.word),
              if (zh.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(zh, style: TextStyle(fontSize: 13, color: muted, height: 1.35)),
              ]
            ]),
          ),
        ],
        const SizedBox(height: 14),
        InkWell(
          onTap: () => context.push('/word-detail', extra: {'wordId': word.id, 'word': word}),
          child: const Text('查看详情 >', style: TextStyle(fontSize: 14, color: _blue, fontWeight: FontWeight.w600)),
        ),
        if (isPlaceholder)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('（登录并拉取数据后显示真实推荐词）', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ),
      ]),
    );
  }

  Widget _richExample(String sentence, String w) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final i = sentence.toLowerCase().indexOf(w.toLowerCase());
    if (i < 0) return Text(sentence, style: TextStyle(fontSize: 14, height: 1.4, color: onSurface));
    return Text.rich(TextSpan(style: TextStyle(fontSize: 14, height: 1.4, color: onSurface), children: [
      TextSpan(text: sentence.substring(0, i)),
      TextSpan(text: sentence.substring(i, i + w.length), style: const TextStyle(color: _blue, fontWeight: FontWeight.w600)),
      TextSpan(text: sentence.substring(i + w.length)),
    ]));
  }
}
