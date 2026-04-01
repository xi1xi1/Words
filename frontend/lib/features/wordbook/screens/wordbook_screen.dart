// frontend/lib/features/wordbook/screens/wordbook_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/wordbook_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/wordbook_model.dart';

class WordbookScreen extends StatefulWidget {
  const WordbookScreen({super.key});

  @override
  State<WordbookScreen> createState() => _WordbookScreenState();
}

class _WordbookScreenState extends State<WordbookScreen> {
  final WordbookService _service = WordbookService();
  bool _loading = true;
  List<WordbookWord> _words = [];

  static const _blue = Color(0xFF4A7DFF);
  static const _bg = Color(0xFFF5F7FA);
  static const _navy = Color(0xFF1A2B48);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getWordbookList();
      setState(() => _words = list);
    } on ApiException catch (_) {
      setState(() => _words = _demoWords);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static final _demoWords = [
    WordbookWord(
      id: 1,
      word: 'serendipity',
      phonetic: '/ˌserənˈdɪpəti/',
      translation: '意外发现美好事物的能力',
      addedAt: DateTime(2026, 3, 10),
    ),
    WordbookWord(
      id: 2,
      word: 'ephemeral',
      phonetic: '/ɪˈfem(ə)rəl/',
      translation: '短暂的，昙花一现的',
      addedAt: DateTime(2026, 3, 9),
    ),
    WordbookWord(
      id: 3,
      word: 'resilience',
      phonetic: '/rɪˈzɪliəns/',
      translation: '恢复力，适应力',
      addedAt: DateTime(2026, 3, 8),
    ),
    WordbookWord(
      id: 4,
      word: 'eloquent',
      phonetic: '/ˈeləkwənt/',
      translation: '雄辩的，有说服力的',
      addedAt: DateTime(2026, 3, 7),
    ),
  ];

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, top),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _words.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _wordCard(_words[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, double top) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 20),
      decoration: const BoxDecoration(color: _blue),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '生词本',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _loading ? '加载中…' : '共 ${_words.length} 个单词',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('开始复习'),
          ),
        ],
      ),
    );
  }

  Widget _wordCard(WordbookWord w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(w.word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
          if (w.phonetic.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(w.phonetic, style: const TextStyle(fontSize: 14, color: Color(0xFF8E9AAF))),
          ],
          const SizedBox(height: 8),
          Text(w.translation, style: const TextStyle(fontSize: 15, color: Color(0xFF333333), height: 1.35)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_fmtDate(w.addedAt), style: const TextStyle(fontSize: 12, color: Color(0xFF8E9AAF))),
          ),
        ],
      ),
    );
  }
}
