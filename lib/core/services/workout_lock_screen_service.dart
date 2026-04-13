import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WorkoutLockScreenSnapshot {
  final bool sessionActive;
  final String workoutName;
  final String currentExerciseName;
  final int currentSetNumber;
  final int currentSetTotal;
  final String? nextExerciseName;
  final int? nextSetNumber;
  final int? nextSetTotal;
  final bool isResting;
  final int? restRemainingSeconds;
  final int? restTotalSeconds;

  const WorkoutLockScreenSnapshot({
    required this.sessionActive,
    required this.workoutName,
    required this.currentExerciseName,
    required this.currentSetNumber,
    required this.currentSetTotal,
    required this.nextExerciseName,
    required this.nextSetNumber,
    required this.nextSetTotal,
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

    await initialize();
    if (!_initialized) return;

    // iOS lock screen updates are throttled during countdown to avoid spammy updates.
    if (Platform.isIOS && isTick) {
      final now = DateTime.now();
      if (_lastIosTickUpdate != null &&
          now.difference(_lastIosTickUpdate!).inSeconds < 15) {
        return;
      }
      _lastIosTickUpdate = now;
    }

    await _requestPermissionsIfNeeded();

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
    if (!_initialized) return;
    try {
      await _notifications.cancel(_notificationId);
    } catch (e) {
      debugPrint('Unable to clear workout lock-screen notification: $e');
    }
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
