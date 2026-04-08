// lib/services/word_service.dart
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/word_model.dart';

class WordService {
  final ApiClient _apiClient = ApiClient();

  Future<DailyWordsResponse> getDailyWords() async {
    final response = await _apiClient.get(ApiConstants.wordsDaily);
    return DailyWordsResponse.fromJson(response);
  }

  Future<({Word? nextWord, LearnProgress progress})> submitLearnResult({
    required int wordId,
    required bool isCorrect,
    required int stage,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.wordsLearn,
      data: {'wordId': wordId, 'isCorrect': isCorrect, 'stage': stage},
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final nextWordData = data['nextWord'] as Map<String, dynamic>?;
    final progress = LearnProgress.fromJson(data);

    return (
      nextWord: nextWordData == null ? null : Word.fromJson(nextWordData),
      progress: progress,
    );
  }

  Future<List<Word>> searchWords({
    required String keyword,
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.wordsSearch,
      queryParams: {'keyword': keyword, 'page': page, 'size': size},
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = (data['content'] ?? data['list'] ?? <dynamic>[]) as List<dynamic>;
    return list.map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Word> getWordDetail(int wordId) async {
    final response = await _apiClient.get('${ApiConstants.wordsDetail}/$wordId');
    final data = response['data'] as Map<String, dynamic>;
    return Word.fromJson(data);
  }
}
