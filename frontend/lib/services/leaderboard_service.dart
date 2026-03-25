// lib/services/leaderboard_service.dart
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  final ApiClient _apiClient = ApiClient();

  Future<LeaderboardResponse> getLeaderboard({
    String type = 'total',
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.leaderboard,
      queryParams: {'type': type, 'limit': limit},
    );
    return LeaderboardResponse.fromJson(response);
  }
}
