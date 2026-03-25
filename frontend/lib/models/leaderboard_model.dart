class LeaderboardResponse {
  final List<LeaderboardEntry> entries;
  final int total;

  LeaderboardResponse({required this.entries, required this.total});

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final list = data['list'] as List<dynamic>;
    return LeaderboardResponse(
      entries: list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {'list': entries.map((e) => e.toJson()).toList(), 'total': total},
    };
  }
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final int level;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.score,
    required this.level,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      username: json['username'] as String,
      score: json['score'] as int,
      level: json['level'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'rank': rank, 'username': username, 'score': score, 'level': level};
  }
}
