import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════
/// HEALTH INTEGRATION SERVICE
/// Cross-platform service for Apple HealthKit & Google Health Connect
/// ═══════════════════════════════════════════════════════════
class HealthIntegrationService {
  static final HealthIntegrationService _instance =
      HealthIntegrationService._internal();
  factory HealthIntegrationService() => _instance;
  HealthIntegrationService._internal();

  final Health _health = Health();
  bool _isInitialized = false;
  bool _isAuthorized = false;
  static const String _iosConnectedKey = 'apple_health_connected_v1';

  /// Data types we want to read
  static final List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  /// Data types we want to write
  static final List<HealthDataType> _writeTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Check if health integration is available on this platform
  bool get isAvailable {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Check if currently authorized
  bool get isAuthorized => _isAuthorized;

  /// Get platform name for display
  String get platformName {
    if (kIsWeb) return 'Web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'Apple Health';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Health Connect';
    }
    return 'Unknown';
  }

  /// Initialize the health service
  Future<void> initialize() async {
    if (_isInitialized || !isAvailable) return;

    try {
      // Configure the health plugin
      await _health.configure();
      _isInitialized = true;

      if (_isIOS) {
        _isAuthorized = await _loadIosConnectedState();
      } else {
        // Android can report real authorization state.
        _isAuthorized = await _health.hasPermissions(_readTypes) ?? false;
      }

      debugPrint(
        'HealthIntegrationService initialized. Authorized: $_isAuthorized',
      );
    } catch (e) {
      debugPrint('Error initializing health service: $e');
    }
  }

  /// Request permissions for health data access
  Future<bool> requestPermissions() async {
    if (!isAvailable) return false;

    try {
      // Ensure plugin is configured before requesting permissions.
      if (!_isInitialized) {
        await initialize();
      }

      // Avoid requesting permissions again once already connected.
      if (_isAuthorized) {
        return true;
      }

      // Build a single, deduplicated list of data types with matching access list.
      // health.requestAuthorization requires one permission entry per data type.
      final accessByType = <HealthDataType, HealthDataAccess>{};
      for (final type in _readTypes) {
        accessByType[type] = HealthDataAccess.READ;
      }
      for (final type in _writeTypes) {
        accessByType[type] = HealthDataAccess.READ_WRITE;
      }

      final types = accessByType.keys.toList(growable: false);
      final permissions = types
          .map((type) => accessByType[type]!)
          .toList(growable: false);

      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      await _setAuthorizedState(authorized);
      debugPrint('Health permissions granted: $authorized');
      return authorized;
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      return false;
    }
  }

  /// Check if Health Connect is installed (Android only)
  Future<bool> isHealthConnectInstalled() async {
    if (!_isAndroid) return true;

    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      debugPrint('Error checking Health Connect status: $e');
      return false;
    }
  }

  /// Install Health Connect (Android only)
  Future<void> installHealthConnect() async {
    if (!_isAndroid) return;
    await _health.installHealthConnect();
  }

  // ═══════════════════════════════════════════════════════════
  // READ METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get steps for today
  Future<int?> getStepsToday() async {
    if (!_isAuthorized) return null;

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps;
    } catch (e) {
      debugPrint('Error getting steps: $e');
      await _handlePotentialPermissionRevocation(e);
      return null;
    }
  }

  /// Get steps for a specific date
  Future<int?> getStepsForDate(DateTime date) async {
    if (!_isAuthorized) return null;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return await _health.getTotalStepsInInterval(startOfDay, endOfDay);
    } catch (e) {
      debugPrint('Error getting steps for date: $e');
      await _handlePotentialPermissionRevocation(e);
      return null;
    }
  }

  /// Get heart rate (most recent reading)
  /// Note: Uses regular HEART_RATE since RESTING_HEART_RATE permission was removed
  Future<int?> getRestingHeartRate() async {
    if (!_isAuthorized) return null;

    try {
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: dayAgo,
        endTime: now,
      );

      if (data.isNotEmpty) {
        // Get the most recent value
        final latest = data.last;
        final value = latest.value;
        if (value is NumericHealthValue) {
          return value.numericValue.toInt();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting heart rate: $e');
      await _handlePotentialPermissionRevocation(e);
      return null;
    }
  }

  /// Get sleep hours for a specific date
  Future<double?> getSleepHours(DateTime date) async {
    if (!_isAuthorized) return null;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_IN_BED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      if (data.isEmpty) return null;

      // Sum up sleep duration in hours
      double totalMinutes = 0;
      for (final point in data) {
        final duration = point.dateTo.difference(point.dateFrom);
        totalMinutes += duration.inMinutes;
      }

      return totalMinutes / 60;
    } catch (e) {
      debugPrint('Error getting sleep: $e');
      await _handlePotentialPermissionRevocation(e);
      return null;
    }
  }

  /// Get active calories burned today
  Future<double?> getActiveCaloriesToday() async {
    if (!_isAuthorized) return null;

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );

      if (data.isEmpty) return null;

      double total = 0;
      for (final point in data) {
        final value = point.value;
        if (value is NumericHealthValue) {
          total += value.numericValue;
        }
      }

      return total;
    } catch (e) {
      debugPrint('Error getting calories: $e');
      await _handlePotentialPermissionRevocation(e);
      return null;
    }
  }

  /// Get current weight (most recent)
  Future<double?> getCurrentWeight() async {
    if (!_isAuthorized) return null;

    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: monthAgo,
        endTime: now,
      );

      if (data.isNotEmpty) {
        final latest = data.last;
        final value = latest.value;
        if (value is NumericHealthValue) {
          return value.numericValue.toDouble();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting weight: $e');
      await _handlePotentialPermissionRevocation(e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // WRITE METHODS
  // ═══════════════════════════════════════════════════════════

  /// Write a completed workout to Health
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required int caloriesBurned,
    String workoutType = 'strength_training',
  }) async {
    if (!_isAuthorized) return false;

    try {
      // Map workout type to HealthWorkoutActivityType
      final activityType = _mapWorkoutType(workoutType);

      // Write the workout
      final success = await _health.writeWorkoutData(
        activityType: activityType,
        start: startTime,
        end: endTime,
        totalEnergyBurned: caloriesBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );

      debugPrint('Workout written to Health: $success');
      return success;
    } catch (e) {
      debugPrint('Error writing workout: $e');
      await _handlePotentialPermissionRevocation(e);
      return false;
    }
  }

  /// Map our workout types to Health workout types
  HealthWorkoutActivityType _mapWorkoutType(String type) {
    switch (type.toLowerCase()) {
      case 'strength_training':
      case 'strength':
        return HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING;
      case 'cardio':
        return HealthWorkoutActivityType.CROSS_TRAINING;
      case 'hiit':
        return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
      case 'yoga':
      case 'mobility':
        return HealthWorkoutActivityType.YOGA;
      case 'running':
        return HealthWorkoutActivityType.RUNNING;
      case 'cycling':
        return HealthWorkoutActivityType.BIKING;
      case 'swimming':
        return HealthWorkoutActivityType.SWIMMING;
      default:
        return HealthWorkoutActivityType.OTHER;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get all health data for syncing to backend
  Future<Map<String, dynamic>> getAllHealthData() async {
    return {
      'steps_today': await getStepsToday(),
      'heart_rate': await getRestingHeartRate(),
      'sleep_hours': await getSleepHours(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      'active_calories': await getActiveCaloriesToday(),
      'weight': await getCurrentWeight(),
      'sync_time': DateTime.now().toIso8601String(),
      'source': platformName,
    };
  }

  /// Disconnect health integration
  Future<void> disconnect() async {
    await _setAuthorizedState(false);
    debugPrint('Health integration disconnected');
  }

  Future<void> _setAuthorizedState(bool value) async {
    _isAuthorized = value;
    if (_isIOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_iosConnectedKey, value);
    }
  }

  Future<bool> _loadIosConnectedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_iosConnectedKey) ?? false;
  }

  bool _looksLikePermissionError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('not authorized') ||
        message.contains('authorization') ||
        message.contains('permission denied') ||
        message.contains('no data access');
  }

  Future<void> _handlePotentialPermissionRevocation(Object error) async {
    if (!_isIOS || !_isAuthorized) return;
    if (_looksLikePermissionError(error)) {
      await _setAuthorizedState(false);
    }
  }
}
