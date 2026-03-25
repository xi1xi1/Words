// lib/services/challenge_service.dart
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/challenge_model.dart';

class ChallengeService {
  final ApiClient _apiClient = ApiClient();

  Future<ChallengeStartResponse> startChallenge(int levelType) async {
    final response = await _apiClient.post(
      ApiConstants.challengeStart,
      data: {'levelType': levelType},
    );
    return ChallengeStartResponse.fromJson(response);
  }

  Future<ChallengeSubmitResponse> submitChallenge({
    required String challengeId,
    required List<ChallengeAnswer> answers,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.challengeSubmit,
      data: {
        'challengeId': challengeId,
        'answers': answers.map((a) => a.toJson()).toList(),
      },
    );
    return ChallengeSubmitResponse.fromJson(response);
  }

  Future<List<BattleRecord>> getChallengeRecords({
    int? levelType,
    int page = 1,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'size': size};
    if (levelType != null) {
      queryParams['levelType'] = levelType;
    }

    final response = await _apiClient.get(
      ApiConstants.challengeRecords,
      queryParams: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    final list = data['list'] as List<dynamic>;
    return list
        .map((e) => BattleRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
