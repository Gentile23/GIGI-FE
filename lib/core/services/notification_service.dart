import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════
/// NOTIFICATION SERVICE - Push Notification Management
/// Handles workout reminders, streak warnings, achievements, etc.
/// ═══════════════════════════════════════════════════════════
///
/// NOTE: This is a preparation service. To fully enable push notifications,
/// add these dependencies to pubspec.yaml:
///
/// dependencies:
///   firebase_core: ^2.24.0
///   firebase_messaging: ^14.7.0
///   flutter_local_notifications: ^16.0.0
///
/// Then run: flutter pub get
/// And configure Firebase in your project.

enum NotificationType {
  workoutReminder, // Daily reminder to workout
  streakWarning, // Streak about to be lost
  streakLost, // Streak was lost
  achievementUnlock, // New achievement/badge
  challengeStart, // New challenge available
  challengeEnding, // Challenge ending soon
  socialActivity, // Friend activity
  weeklyReport, // Weekly progress report
  reEngagement, // Come back notification
  levelUp, // Level up celebration
  newReward, // New reward available
}

class NotificationConfig {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? scheduledTime;
  final bool isImmediate;

  const NotificationConfig({
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.scheduledTime,
    this.isImmediate = false,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  String? _fcmToken;

  // User preferences
  bool _workoutRemindersEnabled = true;
  bool _streakRemindersEnabled = true;
  bool _socialNotificationsEnabled = true;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // In production, initialize Firebase Messaging here:
      // await Firebase.initializeApp();
      // final messaging = FirebaseMessaging.instance;
      //
      // Request permission
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      //
      // Get FCM token
      // _fcmToken = await messaging.getToken();
      //
      // Handle foreground messages
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      //
      // Handle background messages
      // FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      _isInitialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Get FCM token for backend registration
  String? get fcmToken => _fcmToken;

  /// Schedule workout reminder
  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_workoutRemindersEnabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final config = NotificationConfig(
      type: NotificationType.workoutReminder,
      title: 'È ora di allenarti! 💪',
      body: 'Il tuo workout ti aspetta. Non perdere la streak!',
      scheduledTime: scheduledDate,
    );

    await _scheduleNotification(config);
    debugPrint('Workout reminder scheduled for $hour:$minute');
  }

  /// Schedule streak warning (sent at 9 PM if no workout today)
  Future<void> scheduleStreakWarning({required int currentStreak}) async {
    if (!_streakRemindersEnabled || currentStreak == 0) return;

    final now = DateTime.now();
    final warningTime = DateTime(now.year, now.month, now.day, 21, 0);

    if (warningTime.isBefore(now)) return; // Don't schedule if past 9 PM

    final config = NotificationConfig(
      type: NotificationType.streakWarning,
      title: '⚠️ La tua streak è a rischio!',
      body:
          'Hai $currentStreak giorni di streak. Allenati ora per non perderla!',
      scheduledTime: warningTime,
      data: {'streak': currentStreak},
    );

    await _scheduleNotification(config);
  }

  /// Send immediate achievement notification
  Future<void> sendAchievementNotification({
    required String achievementName,
    required String achievementEmoji,
  }) async {
    final config = NotificationConfig(
      type: NotificationType.achievementUnlock,
      title: 'Nuovo Badge Sbloccato! $achievementEmoji',
      body: 'Hai ottenuto: $achievementName',
      isImmediate: true,
      data: {'achievement': achievementName},
    );

    await _sendNotification(config);
  }

  /// Send level up notification
  Future<void> sendLevelUpNotification({required int newLevel}) async {
    final config = NotificationConfig(
      type: NotificationType.levelUp,
      title: '🎉 Livello $newLevel Raggiunto!',
      body: 'Continua così! Nuove sfide ti aspettano.',
      isImmediate: true,
      data: {'level': newLevel},
    );

    await _sendNotification(config);
  }

  /// Send challenge reminder
  Future<void> sendChallengeEndingNotification({
    required String challengeName,
    required Duration timeRemaining,
  }) async {
    String timeText;
    if (timeRemaining.inHours > 0) {
      timeText = '${timeRemaining.inHours} ore';
    } else {
      timeText = '${timeRemaining.inMinutes} minuti';
    }

    final config = NotificationConfig(
      type: NotificationType.challengeEnding,
      title: '⏰ Sfida in scadenza!',
      body: '$challengeName termina tra $timeText',
      isImmediate: true,
      data: {'challenge': challengeName},
    );

    await _sendNotification(config);
  }

  /// Send social activity notification
  Future<void> sendSocialNotification({
    required String friendName,
    required String activity,
  }) async {
    if (!_socialNotificationsEnabled) return;

    final config = NotificationConfig(
      type: NotificationType.socialActivity,
      title: '$friendName è attivo! 👋',
      body: activity,
      isImmediate: true,
    );

    await _sendNotification(config);
  }

  /// Send weekly report notification (Sunday evening)
  Future<void> scheduleWeeklyReport() async {
    final now = DateTime.now();
    // Calculate next Sunday at 7 PM
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final nextSunday = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday),
      19,
      0,
    );

    final config = NotificationConfig(
      type: NotificationType.weeklyReport,
      title: '📊 Il tuo report settimanale è pronto!',
      body: 'Scopri i tuoi progressi di questa settimana',
      scheduledTime: nextSunday,
    );

    await _scheduleNotification(config);
  }

  /// Send re-engagement notification (after 3 days of inactivity)
  Future<void> scheduleReEngagement() async {
    final reEngageTime = DateTime.now().add(const Duration(days: 3));

    final messages = [
      ('Ci manchi! 💪', 'Torna ad allenarti, i tuoi obiettivi ti aspettano.'),
      (
        'Non mollare ora! 🔥',
        'Hai fatto così tanti progressi. Ricomincia oggi.',
      ),
      (
        'Ready per un workout? 🏋️',
        'Bastano 20 minuti per fare la differenza.',
      ),
    ];

    final randomMessage =
        messages[DateTime.now().millisecond % messages.length];

    final config = NotificationConfig(
      type: NotificationType.reEngagement,
      title: randomMessage.$1,
      body: randomMessage.$2,
      scheduledTime: reEngageTime,
    );

    await _scheduleNotification(config);
  }

  // ═══════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════

  void setWorkoutRemindersEnabled(bool enabled) {
    _workoutRemindersEnabled = enabled;
    if (!enabled) {
      cancelNotificationsOfType(NotificationType.workoutReminder);
    }
  }

  void setStreakRemindersEnabled(bool enabled) {
    _streakRemindersEnabled = enabled;
    if (!enabled) {
      cancelNotificationsOfType(NotificationType.streakWarning);
    }
  }

  void setSocialNotificationsEnabled(bool enabled) {
    _socialNotificationsEnabled = enabled;
  }

  void setPreferredWorkoutHour(int hour) {
    scheduleWorkoutReminder(hour: hour, minute: 0);
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _scheduleNotification(NotificationConfig config) async {
    // In production, use flutter_local_notifications:
    //
    // final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    //
    // await flutterLocalNotificationsPlugin.zonedSchedule(
    //   config.type.index,
    //   config.title,
    //   config.body,
    //   tz.TZDateTime.from(config.scheduledTime!, tz.local),
    //   NotificationDetails(...),
    //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //   uiLocalNotificationDateInterpretation:
    //       UILocalNotificationDateInterpretation.absoluteTime,
    // );

    debugPrint(
      'Scheduled notification: ${config.type} at ${config.scheduledTime}',
    );
  }

  Future<void> _sendNotification(NotificationConfig config) async {
    // In production, show local notification immediately:
    //
    // final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    //
    // await flutterLocalNotificationsPlugin.show(
    //   config.type.index,
    //   config.title,
    //   config.body,
    //   NotificationDetails(...),
    // );

    debugPrint('Sent notification: ${config.type} - ${config.title}');
  }

  Future<void> cancelNotificationsOfType(NotificationType type) async {
    // In production:
    // await flutterLocalNotificationsPlugin.cancel(type.index);
    debugPrint('Cancelled notifications of type: $type');
  }

  Future<void> cancelAllNotifications() async {
    // In production:
    // await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Cancelled all notifications');
  }
}

/// ═══════════════════════════════════════════════════════════
/// NOTIFICATION TEMPLATES - Pre-defined notification content
/// ═══════════════════════════════════════════════════════════

class NotificationTemplates {
  static const Map<NotificationType, List<(String title, String body)>>
  templates = {
    NotificationType.workoutReminder: [
      ('È ora di allenarti! 💪', 'Il tuo workout ti aspetta.'),
      ('Pronto per spaccare? 🔥', '20 minuti per sentirti meglio.'),
      ('Il tuo corpo ti ringrazia 🏋️', 'Tempo di workout!'),
    ],
    NotificationType.streakWarning: [
      ('⚠️ Streak a rischio!', 'Non perdere i tuoi progressi!'),
      ('🔥 Salva la tua streak!', 'Mancano poche ore alla mezzanotte.'),
      ('💔 Non lasciarla andare!', 'Un quick workout è tutto ciò che serve.'),
    ],
    NotificationType.reEngagement: [
      ('Ci manchi! 💪', 'Torna ad allenarti.'),
      ('Ready per ricominciare? 🚀', 'Ogni giorno è un nuovo inizio.'),
      ('I tuoi obiettivi ti aspettano 🎯', 'Riprendi da dove avevi lasciato.'),
    ],
  };

  static (String, String) getRandomTemplate(NotificationType type) {
    final typeTemplates = templates[type];
    if (typeTemplates == null || typeTemplates.isEmpty) {
      return ('GIGI', 'Hai una notifica');
    }
    return typeTemplates[DateTime.now().millisecond % typeTemplates.length];
  }
}
