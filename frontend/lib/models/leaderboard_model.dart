// frontend/lib/models/leaderboard_model.dart
class LeaderboardResponse {
  final List<LeaderboardEntry> entries;
  final int? myRank;

  LeaderboardResponse({required this.entries, this.myRank});

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final list = data['list'] as List<dynamic>? ?? [];
    return LeaderboardResponse(
      entries: list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myRank: (data['myRank'] as num?)?.toInt(),
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String username;
  final String? avatar;
  final int totalScore;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatar,
    required this.totalScore,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      totalScore: (json['totalScore'] as num?)?.toInt() ??
          (json['score'] as num?)?.toInt() ??
          0,
    );
  }

  int get score => totalScore;
}
