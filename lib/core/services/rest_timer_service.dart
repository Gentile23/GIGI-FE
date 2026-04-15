import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RestTimerState {
  final bool isActive;
  final String? exerciseId;
  final String? workoutDayId;
  final int setNumber;
  final int totalSeconds;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final bool completed;

  const RestTimerState({
    required this.isActive,
    required this.exerciseId,
    required this.workoutDayId,
    required this.setNumber,
    required this.totalSeconds,
    required this.startedAt,
    required this.endsAt,
    required this.completed,
  });

  const RestTimerState.inactive()
    : isActive = false,
      exerciseId = null,
      workoutDayId = null,
      setNumber = 0,
      totalSeconds = 0,
      startedAt = null,
      endsAt = null,
      completed = false;
}

class RestTimerService extends ChangeNotifier with WidgetsBindingObserver {
  static const int _notificationId = 7101;
  static const String _channelId = 'rest_timer';
  static const String _channelName = 'Timer recupero';
  static const String _channelDescription =
      'Notifiche per la fine del recupero tra i set.';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _timerAudioPlayer = AudioPlayer();
  final Source _countdownSource = AssetSource('sounds/secondi.mp3');
  final Source _timerEndSource = AssetSource('sounds/tempo-finito.mp3');

  Timer? _ticker;
  bool _initialized = false;
  bool _notificationPermissionRequested = false;
  bool _isForeground = true;
  int? _lastRemainingSecond;
  RestTimerState _state = const RestTimerState.inactive();

  RestTimerState get state => _state;
  bool get isActive => _state.isActive;
  String? get exerciseId => _state.exerciseId;
  String? get workoutDayId => _state.workoutDayId;
  int get setNumber => _state.setNumber;
  int get totalSeconds => _state.totalSeconds;

  int get remainingSeconds {
    final endsAt = _state.endsAt;
    if (!_state.isActive || endsAt == null) return 0;
    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  double get progress {
    if (!_state.isActive || _state.totalSeconds <= 0) return 0;
    return (remainingSeconds / _state.totalSeconds).clamp(0.0, 1.0);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    WidgetsBinding.instance.addObserver(this);
    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      ),
    );

    try {
      await _notifications.initialize(settings);
    } catch (e) {
      debugPrint('Rest timer notifications unavailable: $e');
    }

    _initialized = true;
  }

  Future<void> start({
    required String workoutDayId,
    required String exerciseId,
    required int setNumber,
    required int totalSeconds,
  }) async {
    await initialize();

    final now = DateTime.now();
    final safeTotal = totalSeconds > 0 ? totalSeconds : 60;
    final endsAt = now.add(Duration(seconds: safeTotal));

    _state = RestTimerState(
      isActive: true,
      exerciseId: exerciseId,
      workoutDayId: workoutDayId,
      setNumber: setNumber,
      totalSeconds: safeTotal,
      startedAt: now,
      endsAt: endsAt,
      completed: false,
    );
    _lastRemainingSecond = safeTotal;

    _startTicker();
    notifyListeners();
    await _scheduleEndNotification(endsAt);
  }

  Future<void> skip() async {
    _ticker?.cancel();
    _ticker = null;
    _lastRemainingSecond = null;
    _state = const RestTimerState.inactive();
    notifyListeners();
    await _notifications.cancel(_notificationId);
  }

  Future<void> complete() async {
    _ticker?.cancel();
    _ticker = null;
    final shouldPlayEndSound = _state.isActive && _isForeground;
    _state = RestTimerState(
      isActive: false,
      exerciseId: _state.exerciseId,
      workoutDayId: _state.workoutDayId,
      setNumber: _state.setNumber,
      totalSeconds: _state.totalSeconds,
      startedAt: _state.startedAt,
      endsAt: _state.endsAt,
      completed: true,
    );
    _lastRemainingSecond = null;
    if (shouldPlayEndSound) {
      unawaited(_playTimerSound(_timerEndSource));
    }
    notifyListeners();
    await _notifications.cancel(_notificationId);
  }

  void acknowledgeCompletion() {
    if (!_state.completed) return;
    _state = const RestTimerState.inactive();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      _refreshFromClock();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshFromClock();
    });
  }

  void _refreshFromClock() {
    if (!_state.isActive) return;

    final currentRemaining = remainingSeconds;
    if (currentRemaining <= 0) {
      unawaited(complete());
      return;
    }

    if (_isForeground && _lastRemainingSecond != currentRemaining) {
      _lastRemainingSecond = currentRemaining;
      if (currentRemaining <= 3 && currentRemaining >= 1) {
        unawaited(_playTimerSound(_countdownSource));
      }
    }

    notifyListeners();
  }

  Future<void> _playTimerSound(Source source) async {
    try {
      await _timerAudioPlayer.stop();
      await _timerAudioPlayer.play(source, mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Unable to play rest timer sound: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_notificationPermissionRequested) return;
    _notificationPermissionRequested = true;

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true, badge: false);
  }

  Future<void> _scheduleEndNotification(DateTime endsAt) async {
    try {
      await _requestNotificationPermission();
      await _notifications.cancel(_notificationId);
      await _notifications.zonedSchedule(
        _notificationId,
        'Recupero finito',
        'È ora del prossimo set',
        tz.TZDateTime.from(endsAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Unable to schedule rest timer notification: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _timerAudioPlayer.dispose();
    super.dispose();
  }
}
