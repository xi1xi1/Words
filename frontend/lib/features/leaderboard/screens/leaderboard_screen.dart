import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/leaderboard_service.dart';
import '../../../models/leaderboard_model.dart';
import '../../../core/network/api_exception.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _service = LeaderboardService();

  int _tab = 2;
  bool _loading = true;
  LeaderboardResponse? _data;
  String _errorMessage = '';

  static const _primary = Color(0xFF4A7DFF);
  static const _bg = Color(0xFFF7F8FA);
  static const _podiumBg = Color(0xFFFFF9E9);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final type = _tab == 0 ? 'daily' : (_tab == 1 ? 'weekly' : 'total');
      final result = await _service.getLeaderboard(type: type, limit: 50);
      if (mounted) {
        setState(() {
          _data = result;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

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
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_data != null && _data!.entries.length >= 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _podium(),
              ),
            const SizedBox(height: 8),
            Expanded(child: _rankList()),
          ],
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
    final entries = _data!.entries.take(3).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: entries.length > 1
              ? _podiumCard(
                  entries[1].rank,
                  entries[1].username,
                  entries[1].score,
                  false,
                )
              : _podiumCard(2, '---', 0, false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: entries.isNotEmpty
                ? _podiumCard(
                    entries[0].rank,
                    entries[0].username,
                    entries[0].score,
                    true,
                  )
                : _podiumCard(1, '---', 0, true),
          ),
        ),
        Expanded(
          child: entries.length > 2
              ? _podiumCard(
                  entries[2].rank,
                  entries[2].username,
                  entries[2].score,
                  false,
                )
              : _podiumCard(3, '---', 0, false),
        ),
      ],
    );
  }

  Widget _podiumCard(int rank, String name, int score, bool highlight) {
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
          Icon(
            medals[rank.clamp(0, 2)],
            color: colors[rank.clamp(0, 2)],
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            '#$rank',
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
            _formatScore(score),
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

  String _formatScore(int score) {
    if (score >= 10000) {
      return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return score.toString();
  }

  Widget _rankList() {
    final entries = _data?.entries ?? [];
    final restEntries = entries.length > 3 ? entries.skip(3).toList() : entries;

    if (restEntries.isEmpty) {
      return const Center(child: Text('暂无更多数据'));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: restEntries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final entry = restEntries[i];
          return ListTile(
            leading: _leadingForRank(entry.rank),
            title: Text(
              entry.username,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_formatScore(entry.score)} 积分',
              style: const TextStyle(color: Color(0xFF888888)),
            ),
          );
        },
      ),
    );
  }

  Widget _leadingForRank(int idx) {
    if (idx <= 3) {
      final icons = [
        Icons.emoji_events,
        Icons.emoji_events,
        Icons.emoji_events,
      ];
      final colors = [Colors.amber, Colors.blueGrey, Colors.brown];
      return Icon(icons[idx - 1], color: colors[idx - 1], size: 32);
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFFF0F0F0),
      child: Text('$idx', style: const TextStyle(color: Color(0xFF333333))),
    );
  }
}
