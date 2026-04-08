// lib/services/wordbook_service.dart
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/wordbook_model.dart';

class WordbookService {
  final ApiClient _apiClient = ApiClient();

  Future<List<WordbookWord>> getWordbookList({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.wordbookList,
      queryParams: {'page': page, 'size': size},
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = (data['content'] ?? data['list'] ?? <dynamic>[]) as List<dynamic>;
    return list
        .map((e) => WordbookWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToWordbook(int wordId) async {
    await _apiClient.post('${ApiConstants.wordbookAdd}/$wordId');
  }

  Future<void> removeFromWordbook(int wordId) async {
    await _apiClient.delete('${ApiConstants.wordbookRemove}/$wordId');
  }

  Future<AIContentResponse> getAIContent(int wordId) async {
    final response = await _apiClient.get('${ApiConstants.wordbookAi}/$wordId');
    return AIContentResponse.fromJson(response);
  }
}
