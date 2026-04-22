import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/wordbook_provider.dart';
import '../../../models/word_model.dart';
import '../../../models/wordbook_model.dart';
import '../../../services/word_service.dart';
import '../../../services/wordbook_service.dart';

class WordDetailScreen extends StatefulWidget {
  final int wordId;
  final Word? previewWord;

  const WordDetailScreen({super.key, required this.wordId, this.previewWord});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final WordService _wordService = WordService();
  final WordbookService _wordbookService = WordbookService();

  static const _blue = Color(0xFF5B7CF3);
  static const _bg = Color(0xFFF4F6FB);
  static const _navy = Color(0xFF24324A);
  static const _muted = Color(0xFF8C95A3);
  static const _green = Color(0xFF6FD083);
  static const _greenDark = Color(0xFF4BB869);
  static const _cardBorder = Color(0xFFE7EBF3);

  bool _loading = true;
  bool _submitting = false;
  bool _aiLoading = false;
  AIContentResponse? _aiContent;
  Word? _word;

  @override
  void initState() {
    super.initState();
    _word = widget.previewWord;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _wordService.getWordDetail(widget.wordId);
      if (!mounted) return;
      setState(() => _word = detail);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateAIMemory() async {
    final word = _word;
    if (_aiLoading) return;

    if (word == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('单词详情加载中，请稍后再试')),
      );
      return;
    }

    if (word.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前单词信息异常，暂时无法生成联想记忆')),
      );
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final response = await _wordbookService.getAIMemoryContent(word.id);
      if (!mounted) return;

      if (!response.hasContent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 暂时没有生成可展示内容，请稍后重试')),
        );
        return;
      }

      setState(() => _aiContent = response);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 联想记忆生成成功')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _toggleWordbook() async {
    final word = _word;
    if (word == null || word.id <= 0 || _submitting) return;
    final provider = context.read<WordbookProvider>();
    final exists = provider.containsWord(word.id);
    setState(() => _submitting = true);
    try {
      if (exists) {
        await provider.removeWord(word.id);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已移出生词本')));
      } else {
        await provider.addWord(word.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入生词本'), backgroundColor: _greenDark),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = _word;
    final inWordbook =
        word != null && context.watch<WordbookProvider>().containsWord(word.id);
    final examples = _buildExamplePairs(word?.example ?? const <String>[]);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(word),
          Expanded(
            child: _loading && word == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -12),
                          child: _buildMeaningCard(word),
                        ),
                        _buildExamplesCard(examples, word?.word ?? ''),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(inWordbook),
    );
  }

  Widget _buildHeader(Word? word) {
    final level = word?.levelLabel?.isNotEmpty == true
        ? word!.levelLabel!
        : '高级';
    final phonetic = word?.phonetic.isNotEmpty == true
        ? word!.phonetic
        : '/ˌserənˈdɪpəti/';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        10,
        MediaQuery.paddingOf(context).top + 6,
        10,
        28,
      ),
      decoration: const BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            word?.word ?? '加载中...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                phonetic,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.volume_up_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningCard(Word? word) {
    final part = word?.partOfSpeech?.isNotEmpty == true
        ? word!.partOfSpeech!
        : '名词';
    final meanings = word?.meaning.isNotEmpty == true
        ? word!.meaning
        : const ['意外发现有价值或令人愉快的事物的能力'];

    return _sectionCard(
      title: '释义',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              part,
              style: const TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...meanings.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: const TextStyle(fontSize: 16, color: _navy, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesCard(
    List<MapEntry<String, String>> examples,
    String word,
  ) {
    final aiContent = _aiContent;
    final hasAiContent = aiContent?.hasContent ?? false;

    return Column(
      children: [
        _sectionCard(
          titleWidget: Row(
            children: [
              const Text('例句'),
              const Spacer(),
              if (!hasAiContent)
                TextButton.icon(
                  onPressed: _aiLoading ? null : _generateAIMemory,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: _aiLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('生成联想记忆', style: TextStyle(fontSize: 13)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Color(0xFFFF9800),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '联想已生成',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(examples.length, (index) {
                final item = examples[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.key,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _navy,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _muted,
                        height: 1.5,
                      ),
                    ),
                    if (index != examples.length - 1) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: _cardBorder),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
        if (hasAiContent) _buildAIMemoryCard(aiContent!, word),
      ],
    );
  }

  Widget _buildAIMemoryCard(AIContentResponse aiContent, String word) {
    return _sectionCard(
      titleWidget: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: Color(0xFFFF9800)),
          SizedBox(width: 8),
          Text('AI联想记忆'),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aiContent.meaning.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCE4FF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: _blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '记忆锚点：${aiContent.meaning}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _navy,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          ..._buildMemorySections(aiContent),
          if (aiContent.summary.trim().isNotEmpty) ...[
            if (_hasAnyMemoryBlock(aiContent)) const SizedBox(height: 14),
            _buildMemorySummary(aiContent.summary),
          ],
          if (aiContent.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              aiContent.notes,
              style: const TextStyle(
                fontSize: 12,
                color: _muted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMemorySections(AIContentResponse aiContent) {
    final blocks = <MemoryHintBlock?>[
      aiContent.homophonic,
      aiContent.morpheme,
      aiContent.story,
    ].whereType<MemoryHintBlock>().toList();

    final widgets = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      widgets.add(_buildMemoryBlock(blocks[i]));
      if (i != blocks.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  bool _hasAnyMemoryBlock(AIContentResponse aiContent) {
    return (aiContent.homophonic?.isNotEmpty ?? false) ||
        (aiContent.morpheme?.isNotEmpty ?? false) ||
        (aiContent.story?.isNotEmpty ?? false);
  }

  Widget _buildMemoryBlock(MemoryHintBlock block) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: Color(0xFFFF9800),
              ),
              const SizedBox(width: 6),
              Text(
                block.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            block.content,
            style: const TextStyle(
              fontSize: 16,
              color: _navy,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (block.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              block.explanation,
              style: const TextStyle(
                fontSize: 14,
                color: _muted,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemorySummary(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7E4C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt_rounded, size: 16, color: _greenDark),
              SizedBox(width: 6),
              Text(
                '一句记牢',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 15,
              color: _navy,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordGroupCard(String title, List<String> words, bool positive) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: words.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: positive ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: positive ? null : Border.all(color: _cardBorder),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    color: positive ? Colors.white : _navy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    String? title,
    Widget? titleWidget,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleWidget != null)
            titleWidget
          else if (title != null)
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool inWordbook) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _toggleWordbook,
          style: ElevatedButton.styleFrom(
            backgroundColor: inWordbook ? _greenDark : _green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.note_add_outlined, size: 18),
          label: Text(
            inWordbook ? '已加入生词本' : '加入生词本',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  List<MapEntry<String, String>> _buildExamplePairs(List<String> rawExamples) {
    final items = rawExamples.isNotEmpty
        ? rawExamples
        : const [
            'Meeting you was pure serendipity.',
            '遇见你纯属意外的幸运。',
            'The discovery was a happy serendipity.',
            '这个发现是一次幸运的意外。',
          ];

    final pairs = <MapEntry<String, String>>[];
    for (var i = 0; i < items.length; i += 2) {
      pairs.add(MapEntry(items[i], i + 1 < items.length ? items[i + 1] : ''));
    }
    return pairs;
  }
}
