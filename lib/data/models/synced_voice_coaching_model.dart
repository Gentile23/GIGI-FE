/// Synced voice coaching scripts for real-time workout synchronization
class SyncedVoiceCoaching {
  final bool success;
  final String exerciseName;
  final String userName;
  final int sets;
  final int reps;
  final int restSeconds;
  final SyncedScripts scripts;

  SyncedVoiceCoaching({
    required this.success,
    required this.exerciseName,
    required this.userName,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.scripts,
  });

  factory SyncedVoiceCoaching.fromJson(Map<String, dynamic> json) {
    return SyncedVoiceCoaching(
      success: json['success'] ?? false,
      exerciseName: json['exercise'] ?? '',
      userName: json['user_name'] ?? '',
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      restSeconds: json['rest_seconds'] ?? 90,
      scripts: SyncedScripts.fromJson(json['scripts'] ?? {}),
    );
  }
}

class SyncedScripts {
  final List<PreSetScript> preSetScripts;
  final List<RepCue> repCues;
  final String postSetScript;
  final RestCountdown restCountdown;
  final String workoutComplete;

  SyncedScripts({
    required this.preSetScripts,
    required this.repCues,
    required this.postSetScript,
    required this.restCountdown,
    required this.workoutComplete,
  });

  factory SyncedScripts.fromJson(Map<String, dynamic> json) {
    return SyncedScripts(
      preSetScripts: (json['pre_set_scripts'] as List? ?? [])
          .map((e) => PreSetScript.fromJson(e))
          .toList(),
      repCues: (json['rep_cues'] as List? ?? [])
          .map((e) => RepCue.fromJson(e))
          .toList(),
      postSetScript: json['post_set_script'] ?? '',
      restCountdown: RestCountdown.fromJson(json['rest_countdown'] ?? {}),
      workoutComplete: json['workout_complete'] ?? '',
    );
  }

  /// Get pre-set script for specific set number
  PreSetScript? getPreSetScript(int setNumber) {
    return preSetScripts.firstWhere(
      (s) => s.setNumber == setNumber,
      orElse: () =>
          PreSetScript(setNumber: setNumber, text: 'Via!', durationSeconds: 3),
    );
  }

  /// Get rep cue for specific rep number
  RepCue? getRepCue(int repNumber) {
    if (repNumber < 1 || repNumber > repCues.length) return null;
    return repCues.firstWhere(
      (r) => r.repNumber == repNumber,
      orElse: () =>
          RepCue(repNumber: repNumber, text: 'Forza!', phase: 'concentric'),
    );
  }
}

class PreSetScript {
  final int setNumber;
  final String text;
  final int durationSeconds;

  PreSetScript({
    required this.setNumber,
    required this.text,
    required this.durationSeconds,
  });

  factory PreSetScript.fromJson(Map<String, dynamic> json) {
    return PreSetScript(
      setNumber: json['set_number'] ?? 1,
      text: json['text'] ?? '',
      durationSeconds: json['duration_seconds'] ?? 4,
    );
  }
}

class RepCue {
  final int repNumber;
  final String text;
  final String phase; // eccentric, concentric, isometric

  RepCue({required this.repNumber, required this.text, required this.phase});

  factory RepCue.fromJson(Map<String, dynamic> json) {
    return RepCue(
      repNumber: json['rep_number'] ?? 1,
      text: json['text'] ?? '',
      phase: json['phase'] ?? 'concentric',
    );
  }
}

class RestCountdown {
  final String sixtySec;
  final String thirtySec;
  final String tenSec;
  final String fiveSec;
  final String threeSec;
  final String twoSec;
  final String oneSec;

  RestCountdown({
    required this.sixtySec,
    required this.thirtySec,
    required this.tenSec,
    required this.fiveSec,
    required this.threeSec,
    required this.twoSec,
    required this.oneSec,
  });

  factory RestCountdown.fromJson(Map<String, dynamic> json) {
    return RestCountdown(
      sixtySec: json['sixty_sec'] ?? 'Un minuto',
      thirtySec: json['thirty_sec'] ?? 'Trenta secondi',
      tenSec: json['ten_sec'] ?? 'Dieci secondi',
      fiveSec: json['five_sec'] ?? 'Cinque',
      threeSec: json['three_sec'] ?? 'Tre',
      twoSec: json['two_sec'] ?? 'Due',
      oneSec: json['one_sec'] ?? 'Uno... Via!',
    );
  }

  /// Get message for given seconds remaining
  String? getMessageForSeconds(int seconds) {
    switch (seconds) {
      case 60:
        return sixtySec;
      case 30:
        return thirtySec;
      case 10:
        return tenSec;
      case 5:
        return fiveSec;
      case 3:
        return threeSec;
      case 2:
        return twoSec;
      case 1:
        return oneSec;
      default:
        return null;
    }
  }
}
