import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/wordbook_provider.dart';
import '../../../models/wordbook_model.dart';

class WordbookScreen extends StatefulWidget {
  const WordbookScreen({super.key});

  @override
  State<WordbookScreen> createState() => _WordbookScreenState();
}

class _WordbookScreenState extends State<WordbookScreen> {
  static const _blue = Color(0xFF4A7DFF);
  static const _bg = Color(0xFFF5F7FA);
  static const _navy = Color(0xFF1A2B48);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordbookProvider>().load(force: true);
    });
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _removeWord(WordbookWord word) async {
    final wid = word.wordId;
    if (wid <= 0) return;
    try {
      await context.read<WordbookProvider>().removeWord(wid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已从生词本移除 ${word.word}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  void _openWordDetail(WordbookWord word) {
    context.push('/word-detail', extra: {'wordId': word.wordId});
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final provider = context.watch<WordbookProvider>();
    final words = provider.words;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, top, provider.loading, words.length),
          Expanded(
            child: provider.loading && !provider.initialized
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<WordbookProvider>().load(force: true),
                    child: words.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('生词本还是空的，去首页添加几个单词吧')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: words.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _wordCard(words[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, double top, bool loading, int count) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 20),
      decoration: const BoxDecoration(color: _blue),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '生词本',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loading ? '加载中…' : '共 $count 个单词',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: count > 0 ? () => context.push('/review') : null,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('开始复习'),
          ),
        ],
      ),
    );
  }

  Widget _wordCard(WordbookWord w) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openWordDetail(w),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        w.word,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeWord(w),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFB0B8C4),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (w.phonetic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    w.phonetic,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E9AAF),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  w.translation,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _fmtDate(w.addedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E9AAF),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB0B8C4),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
