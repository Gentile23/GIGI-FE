library;

/// Injury tracking model with detailed muscle, joint, and bone areas
import 'package:flutter/material.dart';
import 'package:gigi/l10n/app_localizations.dart';

class InjuryModel {
  final String id;
  final InjuryCategory category;
  final InjuryArea area;
  final InjurySeverity severity;
  final InjuryStatus status;
  final InjuryTiming timing; // current or past
  final String? side; // 'left', 'right', 'both', 'bilateral', 'notApplicable'
  final bool? isOvercome; // For past injuries - whether it has been overcome
  final String? painfulExercises; // Exercises that cause pain
  final String? notes;
  final DateTime reportedAt;

  InjuryModel({
    required this.id,
    required this.category,
    required this.area,
    required this.severity,
    required this.status,
    this.timing = InjuryTiming.current,
    this.side,
    this.isOvercome,
    this.painfulExercises,
    this.notes,
    required this.reportedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'area': area.name,
      'severity': severity.name,
      'status': status.name,
      'timing': timing.name,
      'side': side,
      'is_overcome': isOvercome,
      'painful_exercises': painfulExercises,
      'notes': notes,
      'reportedAt': reportedAt.toIso8601String(),
    };
  }

  factory InjuryModel.fromJson(Map<String, dynamic> json) {
    return InjuryModel(
      id: json['id'] as String,
      category: InjuryCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      area: InjuryArea.values.firstWhere((e) => e.name == json['area']),
      severity: InjurySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      status: InjuryStatus.values.firstWhere((e) => e.name == json['status']),
      timing: json['timing'] != null
          ? InjuryTiming.values.firstWhere((e) => e.name == json['timing'])
          : InjuryTiming.current,
      side: json['side'] as String?,
      isOvercome: json['is_overcome'] as bool?,
      painfulExercises: json['painful_exercises'] as String?,
      notes: json['notes'] as String?,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
    );
  }

  InjuryModel copyWith({
    String? id,
    InjuryCategory? category,
    InjuryArea? area,
    InjurySeverity? severity,
    InjuryStatus? status,
    InjuryTiming? timing,
    String? side,
    bool? isOvercome,
    String? painfulExercises,
    String? notes,
    DateTime? reportedAt,
  }) {
    return InjuryModel(
      id: id ?? this.id,
      category: category ?? this.category,
      area: area ?? this.area,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      timing: timing ?? this.timing,
      side: side ?? this.side,
      isOvercome: isOvercome ?? this.isOvercome,
      painfulExercises: painfulExercises ?? this.painfulExercises,
      notes: notes ?? this.notes,
      reportedAt: reportedAt ?? this.reportedAt,
    );
  }
}

/// Category of injury
enum InjuryCategory { muscular, articular, bone }

/// Specific injury areas covering all major muscle groups, joints, and bones
enum InjuryArea {
  // Muscular areas
  neck,
  trapezius,
  deltoids,
  pectorals,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  lowerBack,
  upperBack,
  lats,
  glutes,
  hipFlexors,
  quadriceps,
  hamstrings,
  calves,
  adductors,
  abductors,
  rotatorCuff,

  // Articular (joints)
  cervicalSpine,
  shoulder,
  elbow,
  wrist,
  fingers,
  thoracicSpine,
  lumbarSpine,
  hip,
  knee,
  ankle,
  toes,
  sacroiliac,
  temporomandibular,

  // Bone areas
  skull,
  clavicle,
  scapula,
  ribs,
  sternum,
  humerus,
  radius,
  ulna,
  carpals,
  metacarpals,
  phalangesHand,
  vertebrae,
  pelvis,
  femur,
  patella,
  tibia,
  fibula,
  tarsals,
  metatarsals,
  phalangesFoot,
}

/// Severity level of injury
enum InjurySeverity { mild, moderate, severe }

/// Timing of injury (current or past)
enum InjuryTiming { current, past }

/// Current status of injury
enum InjuryStatus { active, recovering, resolved }

/// Extension methods for better UI display
extension InjuryCategoryExtension on InjuryCategory {
  String get displayName {
    switch (this) {
      case InjuryCategory.muscular:
        return 'Muscolare';
      case InjuryCategory.articular:
        return 'Articolare';
      case InjuryCategory.bone:
        return 'Osseo';
    }
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case InjuryCategory.muscular:
        return AppLocalizations.of(context)!.injuryMuscular;
      case InjuryCategory.articular:
        return AppLocalizations.of(context)!.injuryArticular;
      case InjuryCategory.bone:
        return AppLocalizations.of(context)!.injuryBone;
    }
  }

  String get icon {
    switch (this) {
      case InjuryCategory.muscular:
        return '💪';
      case InjuryCategory.articular:
        return '🦴';
      case InjuryCategory.bone:
        return '🩻';
    }
  }
}

extension InjuryAreaExtension on InjuryArea {
  String get displayName {
    switch (this) {
      // Muscular
      case InjuryArea.neck:
        return 'Collo';
      case InjuryArea.trapezius:
        return 'Trapezio';
      case InjuryArea.deltoids:
        return 'Deltoidi';
      case InjuryArea.pectorals:
        return 'Pettorali';
      case InjuryArea.biceps:
        return 'Bicipiti';
      case InjuryArea.triceps:
        return 'Tricipiti';
      case InjuryArea.forearms:
        return 'Avambracci';
      case InjuryArea.abs:
        return 'Addominali';
      case InjuryArea.obliques:
        return 'Obliqui';
      case InjuryArea.lowerBack:
        return 'Zona Lombare';
      case InjuryArea.upperBack:
        return 'Parte Alta Schiena';
      case InjuryArea.lats:
        return 'Dorsali';
      case InjuryArea.glutes:
        return 'Glutei';
      case InjuryArea.hipFlexors:
        return 'Flessori Anca';
      case InjuryArea.quadriceps:
        return 'Quadricipiti';
      case InjuryArea.hamstrings:
        return 'Femorali';
      case InjuryArea.calves:
        return 'Polpacci';
      case InjuryArea.adductors:
        return 'Adduttori';
      case InjuryArea.abductors:
        return 'Abduttori';
      case InjuryArea.rotatorCuff:
        return 'Cuffia Rotatori';

      // Articular
      case InjuryArea.cervicalSpine:
        return 'Colonna Cervicale';
      case InjuryArea.shoulder:
        return 'Spalla';
      case InjuryArea.elbow:
        return 'Gomito';
      case InjuryArea.wrist:
        return 'Polso';
      case InjuryArea.fingers:
        return 'Dita Mano';
      case InjuryArea.thoracicSpine:
        return 'Colonna Toracica';
      case InjuryArea.lumbarSpine:
        return 'Colonna Lombare';
      case InjuryArea.hip:
        return 'Anca';
      case InjuryArea.knee:
        return 'Ginocchio';
      case InjuryArea.ankle:
        return 'Caviglia';
      case InjuryArea.toes:
        return 'Dita Piede';
      case InjuryArea.sacroiliac:
        return 'Sacroiliaca';
      case InjuryArea.temporomandibular:
        return 'Temporo-Mandibolare';

      // Bone
      case InjuryArea.skull:
        return 'Cranio';
      case InjuryArea.clavicle:
        return 'Clavicola';
      case InjuryArea.scapula:
        return 'Scapola';
      case InjuryArea.ribs:
        return 'Costole';
      case InjuryArea.sternum:
        return 'Sterno';
      case InjuryArea.humerus:
        return 'Omero';
      case InjuryArea.radius:
        return 'Radio';
      case InjuryArea.ulna:
        return 'Ulna';
      case InjuryArea.carpals:
        return 'Carpo';
      case InjuryArea.metacarpals:
        return 'Metacarpo';
      case InjuryArea.phalangesHand:
        return 'Falangi Mano';
      case InjuryArea.vertebrae:
        return 'Vertebre';
      case InjuryArea.pelvis:
        return 'Bacino';
      case InjuryArea.femur:
        return 'Femore';
      case InjuryArea.patella:
        return 'Rotula';
      case InjuryArea.tibia:
        return 'Tibia';
      case InjuryArea.fibula:
        return 'Perone';
      case InjuryArea.tarsals:
        return 'Tarso';
      case InjuryArea.metatarsals:
        return 'Metatarso';
      case InjuryArea.phalangesFoot:
        return 'Falangi Piede';
    }
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      // Muscular
      case InjuryArea.neck:
        return AppLocalizations.of(context)!.injuryAreaNeck;
      case InjuryArea.trapezius:
        return AppLocalizations.of(context)!.injuryAreaTrapezius;
      case InjuryArea.deltoids:
        return AppLocalizations.of(context)!.injuryAreaDeltoids;
      case InjuryArea.pectorals:
        return AppLocalizations.of(context)!.injuryAreaPectorals;
      case InjuryArea.biceps:
        return AppLocalizations.of(context)!.injuryAreaBiceps;
      case InjuryArea.triceps:
        return AppLocalizations.of(context)!.injuryAreaTriceps;
      case InjuryArea.forearms:
        return AppLocalizations.of(context)!.injuryAreaForearms;
      case InjuryArea.abs:
        return AppLocalizations.of(context)!.injuryAreaAbs;
      case InjuryArea.obliques:
        return AppLocalizations.of(context)!.injuryAreaObliques;
      case InjuryArea.lowerBack:
        return AppLocalizations.of(context)!.injuryAreaLowerBack;
      case InjuryArea.upperBack:
        return AppLocalizations.of(context)!.injuryAreaUpperBack;
      case InjuryArea.lats:
        return AppLocalizations.of(context)!.injuryAreaLats;
      case InjuryArea.glutes:
        return AppLocalizations.of(context)!.injuryAreaGlutes;
      case InjuryArea.hipFlexors:
        return AppLocalizations.of(context)!.injuryAreaHipFlexors;
      case InjuryArea.quadriceps:
        return AppLocalizations.of(context)!.injuryAreaQuadriceps;
      case InjuryArea.hamstrings:
        return AppLocalizations.of(context)!.injuryAreaHamstrings;
      case InjuryArea.calves:
        return AppLocalizations.of(context)!.injuryAreaCalves;
      case InjuryArea.adductors:
        return AppLocalizations.of(context)!.injuryAreaAdductors;
      case InjuryArea.abductors:
        return AppLocalizations.of(context)!.injuryAreaAbductors;
      case InjuryArea.rotatorCuff:
        return AppLocalizations.of(context)!.injuryAreaRotatorCuff;

      // Articular
      case InjuryArea.cervicalSpine:
        return AppLocalizations.of(context)!.injuryAreaCervicalSpine;
      case InjuryArea.shoulder:
        return AppLocalizations.of(context)!.injuryAreaShoulder;
      case InjuryArea.elbow:
        return AppLocalizations.of(context)!.injuryAreaElbow;
      case InjuryArea.wrist:
        return AppLocalizations.of(context)!.injuryAreaWrist;
      case InjuryArea.fingers:
        return AppLocalizations.of(context)!.injuryAreaFingers;
      case InjuryArea.thoracicSpine:
        return AppLocalizations.of(context)!.injuryAreaThoracicSpine;
      case InjuryArea.lumbarSpine:
        return AppLocalizations.of(context)!.injuryAreaLumbarSpine;
      case InjuryArea.hip:
        return AppLocalizations.of(context)!.injuryAreaHip;
      case InjuryArea.knee:
        return AppLocalizations.of(context)!.injuryAreaKnee;
      case InjuryArea.ankle:
        return AppLocalizations.of(context)!.injuryAreaAnkle;
      case InjuryArea.toes:
        return AppLocalizations.of(context)!.injuryAreaToes;
      case InjuryArea.sacroiliac:
        return AppLocalizations.of(context)!.injuryAreaSacroiliac;
      case InjuryArea.temporomandibular:
        return AppLocalizations.of(context)!.injuryAreaTemporomandibular;

      // Bone
      case InjuryArea.skull:
        return AppLocalizations.of(context)!.injuryAreaSkull;
      case InjuryArea.clavicle:
        return AppLocalizations.of(context)!.injuryAreaClavicle;
      case InjuryArea.scapula:
        return AppLocalizations.of(context)!.injuryAreaScapula;
      case InjuryArea.ribs:
        return AppLocalizations.of(context)!.injuryAreaRibs;
      case InjuryArea.sternum:
        return AppLocalizations.of(context)!.injuryAreaSternum;
      case InjuryArea.humerus:
        return AppLocalizations.of(context)!.injuryAreaHumerus;
      case InjuryArea.radius:
        return AppLocalizations.of(context)!.injuryAreaRadius;
      case InjuryArea.ulna:
        return AppLocalizations.of(context)!.injuryAreaUlna;
      case InjuryArea.carpals:
        return AppLocalizations.of(context)!.injuryAreaCarpals;
      case InjuryArea.metacarpals:
        return AppLocalizations.of(context)!.injuryAreaMetacarpals;
      case InjuryArea.phalangesHand:
        return AppLocalizations.of(context)!.injuryAreaPhalangesHand;
      case InjuryArea.vertebrae:
        return AppLocalizations.of(context)!.injuryAreaVertebrae;
      case InjuryArea.pelvis:
        return AppLocalizations.of(context)!.injuryAreaPelvis;
      case InjuryArea.femur:
        return AppLocalizations.of(context)!.injuryAreaFemur;
      case InjuryArea.patella:
        return AppLocalizations.of(context)!.injuryAreaPatella;
      case InjuryArea.tibia:
        return AppLocalizations.of(context)!.injuryAreaTibia;
      case InjuryArea.fibula:
        return AppLocalizations.of(context)!.injuryAreaFibula;
      case InjuryArea.tarsals:
        return AppLocalizations.of(context)!.injuryAreaTarsals;
      case InjuryArea.metatarsals:
        return AppLocalizations.of(context)!.injuryAreaMetatarsals;
      case InjuryArea.phalangesFoot:
        return AppLocalizations.of(context)!.injuryAreaPhalangesFoot;
    }
  }

  InjuryCategory get category {
    if ([
      InjuryArea.neck,
      InjuryArea.trapezius,
      InjuryArea.deltoids,
      InjuryArea.pectorals,
      InjuryArea.biceps,
      InjuryArea.triceps,
      InjuryArea.forearms,
      InjuryArea.abs,
      InjuryArea.obliques,
      InjuryArea.lowerBack,
      InjuryArea.upperBack,
      InjuryArea.lats,
      InjuryArea.glutes,
      InjuryArea.hipFlexors,
      InjuryArea.quadriceps,
      InjuryArea.hamstrings,
      InjuryArea.calves,
      InjuryArea.adductors,
      InjuryArea.abductors,
      InjuryArea.rotatorCuff,
    ].contains(this)) {
      return InjuryCategory.muscular;
    } else if ([
      InjuryArea.cervicalSpine,
      InjuryArea.shoulder,
      InjuryArea.elbow,
      InjuryArea.wrist,
      InjuryArea.fingers,
      InjuryArea.thoracicSpine,
      InjuryArea.lumbarSpine,
      InjuryArea.hip,
      InjuryArea.knee,
      InjuryArea.ankle,
      InjuryArea.toes,
      InjuryArea.sacroiliac,
      InjuryArea.temporomandibular,
    ].contains(this)) {
      return InjuryCategory.articular;
    } else {
      return InjuryCategory.bone;
    }
  }
}

extension InjurySeverityExtension on InjurySeverity {
  String get displayName {
    switch (this) {
      case InjurySeverity.mild:
        return 'Lieve';
      case InjurySeverity.moderate:
        return 'Moderato';
      case InjurySeverity.severe:
        return 'Grave';
    }
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case InjurySeverity.mild:
        return AppLocalizations.of(context)!.injurySeverityMild;
      case InjurySeverity.moderate:
        return AppLocalizations.of(context)!.injurySeverityModerate;
      case InjurySeverity.severe:
        return AppLocalizations.of(context)!.injurySeveritySevere;
    }
  }

  String get icon {
    switch (this) {
      case InjurySeverity.mild:
        return '🟢';
      case InjurySeverity.moderate:
        return '🟡';
      case InjurySeverity.severe:
        return '🔴';
    }
  }
}

extension InjuryTimingExtension on InjuryTiming {
  String get displayName {
    switch (this) {
      case InjuryTiming.current:
        return 'Attuale';
      case InjuryTiming.past:
        return 'Passato';
    }
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case InjuryTiming.current:
        return AppLocalizations.of(context)!.injuryTimingCurrent;
      case InjuryTiming.past:
        return AppLocalizations.of(context)!.injuryTimingPast;
    }
  }

  String get icon {
    switch (this) {
      case InjuryTiming.current:
        return '🔴';
      case InjuryTiming.past:
        return '🟢';
    }
  }
}

extension InjuryStatusExtension on InjuryStatus {
  String get displayName {
    switch (this) {
      case InjuryStatus.active:
        return 'Attivo';
      case InjuryStatus.recovering:
        return 'In Recupero';
      case InjuryStatus.resolved:
        return 'Risolto';
    }
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case InjuryStatus.active:
        return AppLocalizations.of(context)!.injuryStatusActive;
      case InjuryStatus.recovering:
        return AppLocalizations.of(context)!.injuryStatusRecovering;
      case InjuryStatus.resolved:
        return AppLocalizations.of(context)!.injuryStatusResolved;
    }
  }
}
