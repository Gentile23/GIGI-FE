import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/form_analysis_model.dart';
import 'api_client.dart';

class FormAnalysisService {
  final ApiClient _apiClient;

  FormAnalysisService(this._apiClient);

  /// Check user's remaining quota
  Future<FormAnalysisQuota?> checkQuota() async {
    try {
      final response = await _apiClient.dio.get('/form-analysis/quota');
      return FormAnalysisQuota.fromJson(response.data);
    } catch (e) {
      debugPrint('Error checking quota: $e');
      return null;
    }
  }

  /// Submit video for analysis
  Future<FormAnalysis?> analyzeVideo({
    required XFile videoFile,
    required String exerciseName,
    int? exerciseId,
    Function(int, int)? onProgress,
  }) async {
    try {
      MultipartFile videoPart;

      if (kIsWeb) {
        // On Web, use bytes
        videoPart = MultipartFile.fromBytes(
          await videoFile.readAsBytes(),
          filename: 'exercise_video.mp4',
        );
      } else {
        // On Mobile/Desktop, use file path
        videoPart = await MultipartFile.fromFile(
          videoFile.path,
          filename: 'exercise_video.mp4',
        );
      }

      final formData = FormData.fromMap({
        'video': videoPart,
        'exercise_name': exerciseName,
        if (exerciseId != null) 'exercise_id': exerciseId,
      });

      final response = await _apiClient.dio.post(
        '/form-analysis/analyze',
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.data['success'] == true) {
        return FormAnalysis.fromJson(response.data['analysis']);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint('Analysis API Error: ${e.response?.data}');
        debugPrint('Status Code: ${e.response?.statusCode}');
      }
      debugPrint('Error analyzing video: $e');
      rethrow;
    }
  }

  /// Get analysis history
  Future<List<FormAnalysis>?> getHistory() async {
    try {
      final response = await _apiClient.dio.get('/form-analysis/history');
      return (response.data['analyses'] as List)
          .map((json) => FormAnalysis.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return null;
    }
  }

  /// Get specific analysis
  Future<FormAnalysis?> getAnalysis(int id) async {
    try {
      final response = await _apiClient.dio.get('/form-analysis/$id');
      return FormAnalysis.fromJson(response.data['analysis']);
    } catch (e) {
      debugPrint('Error fetching analysis: $e');
      return null;
    }
  }

  /// Delete analysis
  Future<bool> deleteAnalysis(int id) async {
    try {
      await _apiClient.dio.delete('/form-analysis/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleting analysis: $e');
      return false;
    }
  }
}
