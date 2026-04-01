// frontend/lib/features/offline/screens/offline_words_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OfflineWordsScreen extends StatelessWidget {
  const OfflineWordsScreen({super.key});

  static const _blue = Color(0xFF4A7DFF);
  static const _bg = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context, top)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionTitle('已下载'),
                _downloaded(context, 'CET-6 核心词汇', '2000 词 · 12 MB'),
                _downloaded(context, '托福核心词汇', '3000 词 · 18 MB'),
                _downloaded(context, '雅思核心词汇', '3500 词 · 21 MB'),
                const SizedBox(height: 12),
                _sectionTitle('可下载'),
                _downloadable(context, '考研英语词汇', '5500 词 · 32 MB'),
                _downloadable(context, 'GRE 核心词汇', '6000 词 · 35 MB'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, double top) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 22),
      decoration: const BoxDecoration(color: _blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(height: 4),
          const Text(
            '离线词库',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '已下载 3 个词库，占用 51 MB',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1B))),
    );
  }

  Widget _leadingCheck() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.check_rounded, color: Color(0xFF66CC77), size: 26),
    );
  }

  Widget _leadingDl() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF666666), size: 24),
    );
  }

  Widget _downloaded(BuildContext context, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _leadingCheck(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadable(BuildContext context, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _leadingDl(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('下载', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
