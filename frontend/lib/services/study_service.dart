// lib/services/study_service.dart
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/study_model.dart';

class StudyService {
  final ApiClient _apiClient = ApiClient();

  Future<StudyStats> getStudyStats() async {
    final response = await _apiClient.get(ApiConstants.studyStats);
    return StudyStats.fromJson(response);
  }

  Future<List<StudyTrend>> getStudyTrend({int days = 7}) async {
    final response = await _apiClient.get(
      ApiConstants.studyTrend,
      queryParams: {'days': days},
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => StudyTrend.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LearningCalendar> getStudyCalendar({
    required int year,
    required int month,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.studyCalendar,
      queryParams: {'year': year, 'month': month},
    );
    return LearningCalendar.fromJson(response);
  }
}
