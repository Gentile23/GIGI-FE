import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/validation_utils.dart';
import '../models/form_analysis_model.dart';
import 'api_client.dart';

class FormAnalysisService {
  final ApiClient _apiClient;
  static const int _maxVideoSizeBytes = ValidationUtils.maxFormVideoBytes;
  static const Set<String> _allowedVideoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'webm',
  };

  FormAnalysisService(this._apiClient);

  /// Check user's remaining quota
  Future<FormAnalysisQuota?> checkQuota() async {
    try {
      final response = await _apiClient.dio.get('/form-analysis/quota');
      final payload = _asMap(response.data);
      if (payload == null) return null;
      final quotaPayload = _asMap(payload['data']) ?? payload;
      return FormAnalysisQuota.fromJson(quotaPayload);
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
      final sanitizedExerciseName = ValidationUtils.sanitizeFreeText(
        exerciseName,
        maxLength: ValidationUtils.maxAiLabelLength,
      );
      if (sanitizedExerciseName.isEmpty) {
        throw Exception('Nome esercizio non valido');
      }
      if (ValidationUtils.containsSuspiciousMarkup(sanitizedExerciseName)) {
        throw Exception('Nome esercizio contiene contenuto non consentito');
      }

      final fileName = videoFile.name.toLowerCase();
      final extension = fileName.contains('.') ? fileName.split('.').last : '';
      if (!_allowedVideoExtensions.contains(extension)) {
        throw Exception('Formato video non supportato');
      }

      final fileSize = await videoFile.length();
      if (fileSize <= 0 || fileSize > _maxVideoSizeBytes) {
        throw Exception('Dimensione video non valida (max 100MB)');
      }

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
        'exercise_name': sanitizedExerciseName,
        if (exerciseId != null) 'exercise_id': exerciseId,
      });

      final response = await _apiClient.dio.post(
        '/form-analysis/analyze',
        data: formData,
        onSendProgress: onProgress,
      );

      final payload = _asMap(response.data);
      if (payload == null) return null;
      final analysisPayload =
          _asMap(payload['analysis']) ??
          _asMap(payload['data']) ??
          _asMap(_asMap(payload['result'])?['analysis']);
      final isSuccess = payload['success'] != false;

      if (isSuccess && analysisPayload != null) {
        return FormAnalysis.fromJson(analysisPayload);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint('Analysis API Error on /form-analysis/analyze');
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
      final payload = _asMap(response.data);
      if (payload == null) return null;
      final analysesRaw =
          payload['analyses'] ?? _asMap(payload['data'])?['analyses'];
      final analysesList = analysesRaw is List ? analysesRaw : const [];
      return analysesList
          .map((json) => _asMap(json))
          .whereType<Map<String, dynamic>>()
          .map(FormAnalysis.fromJson)
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
      final payload = _asMap(response.data);
      if (payload == null) return null;
      final analysisPayload =
          _asMap(payload['analysis']) ??
          _asMap(payload['data']) ??
          _asMap(_asMap(payload['result'])?['analysis']);
      if (analysisPayload == null) return null;
      return FormAnalysis.fromJson(analysisPayload);
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

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
