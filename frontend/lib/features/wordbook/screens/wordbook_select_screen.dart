import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _WordbankItem {
  final String title;
  final int count;

  const _WordbankItem(this.title, this.count);
}

class _Category {
  final String name;
  final List<_WordbankItem> items;

  const _Category(this.name, this.items);
}

/// 选择词库
class WordbookSelectScreen extends StatefulWidget {
  const WordbookSelectScreen({super.key});

  @override
  State<WordbookSelectScreen> createState() => _WordbookSelectScreenState();
}

class _WordbookSelectScreenState extends State<WordbookSelectScreen> {
  static const _primary = Color(0xFF5B82F9);
  static const _bg = Color(0xFFF7F8FA);

  final List<_Category> _data = const [
    _Category('大学英语', [
      _WordbankItem('CET-4 核心词汇', 1500),
      _WordbankItem('CET-6 核心词汇', 2000),
    ]),
    _Category('考研', [_WordbankItem('考研英语词汇', 5500)]),
    _Category('留学', [
      _WordbankItem('托福核心词汇', 3000),
      _WordbankItem('雅思核心词汇', 3500),
    ]),
  ];

  String _selectedKey = 'CET-6 核心词汇';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                for (final c in _data) ...[
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...c.items.map(_card),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _confirmBar(context),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 16, 28),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
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
            '选择词库',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '从下方选择适合你的词库',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _card(_WordbankItem item) {
    final sel = item.title == _selectedKey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: sel ? const Color(0xFFE8F0FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _selectedKey = item.title),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? _primary : const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_outlined, color: Color(0xFF666666)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '共 ${item.count} 词',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                if (sel)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _confirmBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已选择：$_selectedKey')),
            );
            context.pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('确认选择', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
