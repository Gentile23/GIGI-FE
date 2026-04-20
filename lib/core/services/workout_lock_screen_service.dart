import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

class WorkoutLockScreenSnapshot {
  final bool sessionActive;
  final String workoutName;
  final String currentExerciseName;
  final int currentSetNumber;
  final int currentSetTotal;
  final String? currentTargetReps;
  final List<String> currentMuscleGroups;
  final List<String> currentSecondaryMuscleGroups;
  final String? nextExerciseName;
  final int? nextSetNumber;
  final int? nextSetTotal;
  final String? nextTargetReps;
  final bool isResting;
  final int? restRemainingSeconds;
  final int? restTotalSeconds;

  const WorkoutLockScreenSnapshot({
    required this.sessionActive,
    required this.workoutName,
    required this.currentExerciseName,
    required this.currentSetNumber,
    required this.currentSetTotal,
    required this.currentTargetReps,
    required this.currentMuscleGroups,
    required this.currentSecondaryMuscleGroups,
    required this.nextExerciseName,
    required this.nextSetNumber,
    required this.nextSetTotal,
    required this.nextTargetReps,
    required this.isResting,
    required this.restRemainingSeconds,
    required this.restTotalSeconds,
  });
}

class WorkoutLockScreenService {
  static const int _notificationId = 7201;
  static const String _channelId = 'workout_lock_screen';
  static const String _channelName = 'Allenamento in corso';
  static const String _channelDescription =
      'Mostra set corrente, prossimo set e recupero nella lock screen.';

  static final WorkoutLockScreenService _instance =
      WorkoutLockScreenService._internal();
  factory WorkoutLockScreenService() => _instance;
  WorkoutLockScreenService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _iosLiveActivityChannel = MethodChannel(
    'it.fitgenius.gigi/workout_live_activity',
  );
  static const MethodChannel _androidNotificationChannel = MethodChannel(
    'it.fitgenius.gigi/workout_notification',
  );

  bool _initialized = false;
  bool _permissionRequested = false;
  DateTime? _lastIosTickUpdate;

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    try {
      await _notifications.initialize(settings);
      _initialized = true;
    } catch (e) {
      debugPrint('Workout lock-screen notifications unavailable: $e');
    }
  }

  Future<void> updateSession(
    WorkoutLockScreenSnapshot snapshot, {
    bool isTick = false,
  }) async {
    if (!snapshot.sessionActive) {
      await clear();
      return;
    }

    if (Platform.isIOS) {
      await _updateIosLiveActivity(snapshot, isTick: isTick);
      return;
    }

    await initialize();
    if (!_initialized) return;

    await _requestPermissionsIfNeeded();

    if (Platform.isAndroid) {
      final didShowNative = await _updateAndroidCustomNotification(snapshot);
      if (didShowNative) return;
    }

    final title = snapshot.isResting
        ? 'Recupero: ${_formatTime(snapshot.restRemainingSeconds ?? 0)}'
        : '${snapshot.currentExerciseName} • Set ${snapshot.currentSetNumber}/${snapshot.currentSetTotal}';

    final body =
        snapshot.nextExerciseName != null &&
            snapshot.nextSetNumber != null &&
            snapshot.nextSetTotal != null
        ? 'Prossimo: ${snapshot.nextExerciseName} • Set ${snapshot.nextSetNumber}/${snapshot.nextSetTotal}'
        : 'Prossimo: Fine allenamento';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      ongoing: true,
      autoCancel: false,
      silent: true,
      category: AndroidNotificationCategory.progress,
      visibility: NotificationVisibility.public,
      showProgress:
          snapshot.isResting &&
          (snapshot.restTotalSeconds ?? 0) > 0 &&
          (snapshot.restRemainingSeconds ?? 0) >= 0,
      maxProgress: snapshot.restTotalSeconds ?? 0,
      progress: snapshot.isResting
          ? ((snapshot.restTotalSeconds ?? 0) -
                    (snapshot.restRemainingSeconds ?? 0))
                .clamp(0, snapshot.restTotalSeconds ?? 0)
          : 0,
      styleInformation: BigTextStyleInformation(
        '$body\n${snapshot.workoutName}',
        contentTitle: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    try {
      await _notifications.show(
        _notificationId,
        title,
        '$body\n${snapshot.workoutName}',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      debugPrint('Unable to show workout lock-screen notification: $e');
    }
  }

  Future<void> clear() async {
    _lastIosTickUpdate = null;
    if (Platform.isIOS) {
      try {
        await _iosLiveActivityChannel.invokeMethod<void>('endWorkoutActivity');
      } catch (e) {
        debugPrint('Unable to end workout Live Activity: $e');
      }
    }
    if (Platform.isAndroid) {
      try {
        await _androidNotificationChannel.invokeMethod<void>(
          'clearWorkoutNotification',
        );
      } catch (e) {
        debugPrint('Unable to clear Android workout notification: $e');
      }
    }
    if (!_initialized) return;
    try {
      await _notifications.cancel(_notificationId);
    } catch (e) {
      debugPrint('Unable to clear workout lock-screen notification: $e');
    }
  }

  Future<bool> _updateAndroidCustomNotification(
    WorkoutLockScreenSnapshot snapshot,
  ) async {
    try {
      await _androidNotificationChannel.invokeMethod<void>(
        'updateWorkoutNotification',
        _snapshotPayload(snapshot),
      );
      return true;
    } catch (e) {
      debugPrint('Unable to update Android workout notification: $e');
      return false;
    }
  }

  Future<void> _updateIosLiveActivity(
    WorkoutLockScreenSnapshot snapshot, {
    required bool isTick,
  }) async {
    if (isTick) {
      final now = DateTime.now();
      if (_lastIosTickUpdate != null &&
          now.difference(_lastIosTickUpdate!).inSeconds < 15) {
        return;
      }
      _lastIosTickUpdate = now;
    }

    try {
      await _iosLiveActivityChannel.invokeMethod<void>(
        'updateWorkoutActivity',
        _snapshotPayload(snapshot),
      );
    } catch (e) {
      debugPrint('Unable to update workout Live Activity: $e');
    }
  }

  Map<String, Object?> _snapshotPayload(WorkoutLockScreenSnapshot snapshot) {
    return {
      'workoutName': snapshot.workoutName,
      'currentExerciseName': snapshot.currentExerciseName,
      'currentSetNumber': snapshot.currentSetNumber,
      'currentSetTotal': snapshot.currentSetTotal,
      'currentTargetReps': snapshot.currentTargetReps,
      'currentMuscleGroups': snapshot.currentMuscleGroups,
      'currentSecondaryMuscleGroups': snapshot.currentSecondaryMuscleGroups,
      'nextExerciseName': snapshot.nextExerciseName,
      'nextSetNumber': snapshot.nextSetNumber,
      'nextSetTotal': snapshot.nextSetTotal,
      'nextTargetReps': snapshot.nextTargetReps,
      'isResting': snapshot.isResting,
      'restRemainingSeconds': snapshot.restRemainingSeconds,
      'restTotalSeconds': snapshot.restTotalSeconds,
    };
  }

  Future<void> _requestPermissionsIfNeeded() async {
    if (_permissionRequested) return;
    _permissionRequested = true;

    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: false);
    } catch (e) {
      debugPrint('Unable to request lock-screen notification permissions: $e');
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    return '$minutes:${rem.toString().padLeft(2, '0')}';
  }
}
