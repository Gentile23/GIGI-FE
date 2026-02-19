import 'structured_voice_coaching_model.dart';
import 'enhanced_voice_coaching_model.dart';

class VoiceCoaching {
  final String exerciseId;
  final String? audioUrl;
  final String? scriptText; // Legacy format - simple text
  final StructuredVoiceCoaching? structuredScript; // Old format - 3 phases
  final EnhancedStructuredVoiceCoaching?
  enhancedScript; // New format - multi-phase
  final MultiPhaseCoaching?
  multiPhase; // Newest format - 3 separate audio files
  final DateTime? generatedAt;
  final bool cached;

  VoiceCoaching({
    required this.exerciseId,
    this.audioUrl,
    this.scriptText,
    this.structuredScript,
    this.enhancedScript,
    this.multiPhase,
    this.generatedAt,
    this.cached = false,
  });

  factory VoiceCoaching.fromJson(Map<String, dynamic> json) {
    // Parse script_text - can be either string (legacy), structured object (old), or enhanced object (new)
    String? simpleText;
    StructuredVoiceCoaching? structured;
    EnhancedStructuredVoiceCoaching? enhanced;
    MultiPhaseCoaching? multiPhaseData;

    // Parse multi-phase coaching data if available
    if (json.containsKey('coaching') && json['coaching'] is Map) {
      multiPhaseData = MultiPhaseCoaching.fromJson(json['coaching']);
    }

    final scriptData = json['script_text'];
    if (scriptData != null) {
      if (scriptData is String) {
        // Legacy format - simple text
        simpleText = scriptData;
      } else if (scriptData is Map<String, dynamic>) {
        // Check if it's enhanced format (has pre_exercise, sets, post_exercise)
        if (scriptData.containsKey('pre_exercise') &&
            scriptData.containsKey('sets') &&
            scriptData.containsKey('post_exercise')) {
          // New enhanced format
          enhanced = EnhancedStructuredVoiceCoaching.fromJson(scriptData);
        }
        // Check if it's old structured format (has preparation, execution_instructions, closing)
        else if (scriptData.containsKey('preparation') &&
            scriptData.containsKey('execution_instructions') &&
            scriptData.containsKey('closing')) {
          // Old structured format
          structured = StructuredVoiceCoaching.fromJson(scriptData);
        } else if (scriptData.containsKey('text')) {
          // Wrapped legacy format
          simpleText = scriptData['text'] as String?;
        }
      }
    }

    return VoiceCoaching(
      exerciseId: json['exercise_id']?.toString() ?? '0',
      audioUrl: json['audio_url']?.toString(),
      scriptText: simpleText,
      structuredScript: structured,
      enhancedScript: enhanced,
      multiPhase: multiPhaseData,
      generatedAt: _parseDate(json['generated_at']),
      cached: _parseBool(json['cached']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final s = value.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'audio_url': audioUrl,
      'script_text':
          enhancedScript?.toJson() ?? structuredScript?.toJson() ?? scriptText,
      'coaching': multiPhase?.toJson(),
      'generated_at': generatedAt?.toIso8601String(),
      'cached': cached,
    };
  }

  bool get isAvailable =>
      (audioUrl != null && audioUrl!.isNotEmpty) || (multiPhase != null);

  /// Check if this voice coaching uses multi-phase format (3 files)
  bool get isMultiPhase => multiPhase != null;

  /// Check if this voice coaching uses enhanced format
  bool get isEnhanced => enhancedScript != null;

  /// Check if this voice coaching uses old structured format
  bool get isStructured => structuredScript != null;

  /// Check if this voice coaching uses legacy simple text format
  bool get isLegacy =>
      scriptText != null && !isStructured && !isEnhanced && !isMultiPhase;

  /// Get total number of reps (works for all formats)
  int? get totalReps {
    if (isMultiPhase) {
      return multiPhase?.duringExecution?.totalReps;
    } else if (isEnhanced) {
      return enhancedScript!.totalReps;
    } else if (isStructured) {
      return structuredScript!.totalReps;
    }
    return null;
  }

  /// Get total number of sets (only for enhanced format)
  int? get totalSets => enhancedScript?.totalSets;
}

class MultiPhaseCoaching {
  final CoachingPhase? preExercise;
  final CoachingPhase? duringExecution;
  final CoachingPhase? postExercise;

  MultiPhaseCoaching({
    this.preExercise,
    this.duringExecution,
    this.postExercise,
  });

  factory MultiPhaseCoaching.fromJson(Map<String, dynamic> json) {
    return MultiPhaseCoaching(
      preExercise: json['pre_exercise'] != null
          ? CoachingPhase.fromJson(json['pre_exercise'])
          : null,
      duringExecution: json['during_execution'] != null
          ? CoachingPhase.fromJson(json['during_execution'])
          : null,
      postExercise: json['post_exercise'] != null
          ? CoachingPhase.fromJson(json['post_exercise'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pre_exercise': preExercise?.toJson(),
      'during_execution': duringExecution?.toJson(),
      'post_exercise': postExercise?.toJson(),
    };
  }
}

class CoachingPhase {
  final String? audioUrl;
  final int? duration;
  final List<dynamic>? interventions;
  final int? totalReps;

  CoachingPhase({
    this.audioUrl,
    this.duration,
    this.interventions,
    this.totalReps,
  });

  factory CoachingPhase.fromJson(Map<String, dynamic> json) {
    return CoachingPhase(
      audioUrl: json['audio_url'] as String?,
      duration: json['duration'] as int?,
      interventions: json['interventions'] as List<dynamic>?,
      totalReps: json['total_reps'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_url': audioUrl,
      'duration': duration,
      'interventions': interventions,
      'total_reps': totalReps,
    };
  }
}
