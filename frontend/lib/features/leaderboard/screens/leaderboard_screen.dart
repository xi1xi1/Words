import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 全服排行榜（UI 与稿一致，列表数据可后续接 API）
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _tab = 2; // 0 今日 1 本周 2 总榜

  static const _primary = Color(0xFF4A7DFF);
  static const _bg = Color(0xFFF7F8FA);
  static const _podiumBg = Color(0xFFFFF9E9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _header(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _tabBar(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _podium(),
          ),
          const SizedBox(height: 8),
          Expanded(child: _rankList()),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        16,
        24,
      ),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(height: 4),
          const Text(
            '全服排行榜',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '与全国学习者一起竞技',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    final labels = ['今日', '本周', '总榜'];
    return Row(
      children: List.generate(3, (i) {
        final sel = _tab == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: Material(
              color: sel ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() => _tab = i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? _primary : const Color(0xFFE0E0E0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF333333),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _podium() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _podiumCard(1, '学霸小王', '92,245', false)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _podiumCard(0, '单词达人', '95,580', true),
          ),
        ),
        Expanded(child: _podiumCard(2, '英语大神', '89,930', false)),
      ],
    );
  }

  Widget _podiumCard(int rank, String name, String score, bool highlight) {
    final medals = [Icons.looks_one, Icons.looks_two, Icons.looks_3];
    final colors = [
      Colors.amber.shade700,
      Colors.blueGrey.shade400,
      Colors.brown.shade400,
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? _podiumBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          Icon(medals[rank], color: colors[rank], size: 28),
          const SizedBox(height: 6),
          Text(
            '#${rank + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: const TextStyle(
              fontSize: 12,
              color: _primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankList() {
    final rows = [
      _Row('单词达人', '95,580', 0, null),
      _Row('学霸小王', '92,245', 1, null),
      _Row('英语大神', '89,930', 2, '+1'),
      _Row('记忆大师', '87,680', 3, '-1'),
      _Row('背单词王', '85,420', 4, '+2'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final r = rows[i];
          return ListTile(
            leading: _leadingForRank(r.rankIdx),
            title: Text(
              r.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${r.score} 积分',
              style: const TextStyle(color: Color(0xFF888888)),
            ),
            trailing: r.delta == null
                ? null
                : Text(
                    r.delta!,
                    style: TextStyle(
                      color: r.delta!.startsWith('+')
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _leadingForRank(int idx) {
    if (idx < 3) {
      final icons = [
        Icons.emoji_events,
        Icons.emoji_events,
        Icons.emoji_events,
      ];
      final colors = [Colors.amber, Colors.blueGrey, Colors.brown];
      return Icon(icons[idx], color: colors[idx], size: 32);
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFFF0F0F0),
      child: Text(
        '${idx + 1}',
        style: const TextStyle(color: Color(0xFF333333)),
      ),
    );
  }
}

class _Row {
  final String name;
  final String score;
  final int rankIdx;
  final String? delta;

  _Row(this.name, this.score, this.rankIdx, this.delta);
}
