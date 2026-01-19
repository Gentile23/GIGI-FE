// Unit tests for Progress and Measurements models
import 'package:flutter_test/flutter_test.dart';

// Mock BodyMeasurement class
class BodyMeasurement {
  final DateTime date;
  final double? weight;
  final double? waist;
  final double? chest;
  final double? hips;
  final double? bicepRight;
  final double? bicepLeft;
  final double? thighRight;
  final double? thighLeft;
  final double? calf;

  BodyMeasurement({
    required this.date,
    this.weight,
    this.waist,
    this.chest,
    this.hips,
    this.bicepRight,
    this.bicepLeft,
    this.thighRight,
    this.thighLeft,
    this.calf,
  });

  double? get averageBicep {
    if (bicepRight == null && bicepLeft == null) return null;
    if (bicepRight == null) return bicepLeft;
    if (bicepLeft == null) return bicepRight;
    return (bicepRight! + bicepLeft!) / 2;
  }

  double? get averageThigh {
    if (thighRight == null && thighLeft == null) return null;
    if (thighRight == null) return thighLeft;
    if (thighLeft == null) return thighRight;
    return (thighRight! + thighLeft!) / 2;
  }

  bool get isComplete {
    return weight != null &&
        waist != null &&
        chest != null &&
        hips != null &&
        bicepRight != null &&
        bicepLeft != null &&
        thighRight != null &&
        thighLeft != null;
  }

  Map<String, double?> toMap() {
    return {
      'weight': weight,
      'waist': waist,
      'chest': chest,
      'hips': hips,
      'bicep_right': bicepRight,
      'bicep_left': bicepLeft,
      'thigh_right': thighRight,
      'thigh_left': thighLeft,
      'calf': calf,
    };
  }
}

// Mock ProgressTracker class
class ProgressTracker {
  final List<BodyMeasurement> measurements;

  ProgressTracker({required this.measurements});

  BodyMeasurement? get latest {
    if (measurements.isEmpty) return null;
    return measurements.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  BodyMeasurement? get oldest {
    if (measurements.isEmpty) return null;
    return measurements.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
  }

  double? get totalWeightChange {
    if (oldest?.weight == null || latest?.weight == null) return null;
    return latest!.weight! - oldest!.weight!;
  }

  double? get totalWaistChange {
    if (oldest?.waist == null || latest?.waist == null) return null;
    return latest!.waist! - oldest!.waist!;
  }

  int get totalDays {
    if (oldest == null || latest == null) return 0;
    return latest!.date.difference(oldest!.date).inDays;
  }

  int get totalMeasurements => measurements.length;

  List<BodyMeasurement> get sortedByDate {
    final sorted = List<BodyMeasurement>.from(measurements);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  double? weightAtDate(DateTime date) {
    for (var m in sortedByDate) {
      if (m.date.year == date.year &&
          m.date.month == date.month &&
          m.date.day == date.day) {
        return m.weight;
      }
    }
    return null;
  }
}

// Mock WeeklyStats class
class WeeklyStats {
  final int workoutsCompleted;
  final int totalMinutes;
  final int totalCaloriesBurned;
  final int streak;
  final double avgWorkoutDuration;

  WeeklyStats({
    required this.workoutsCompleted,
    required this.totalMinutes,
    required this.totalCaloriesBurned,
    required this.streak,
    required this.avgWorkoutDuration,
  });

  bool get isWorkoutGoalMet => workoutsCompleted >= 3;
  bool get isTimeGoalMet => totalMinutes >= 150; // 150 min/week recommended

  double get complianceRate {
    // Assuming 5 workouts/week is 100% compliance
    return (workoutsCompleted / 5.0).clamp(0.0, 1.0);
  }
}

void main() {
  group('BodyMeasurement Model', () {
    test('BodyMeasurement creation', () {
      final measurement = BodyMeasurement(
        date: DateTime(2026, 1, 1),
        weight: 75.0,
        waist: 85.0,
        chest: 100.0,
      );

      expect(measurement.weight, 75.0);
      expect(measurement.waist, 85.0);
      expect(measurement.chest, 100.0);
    });

    test('Average bicep calculation', () {
      final measurement = BodyMeasurement(
        date: DateTime.now(),
        bicepRight: 35.0,
        bicepLeft: 34.0,
      );

      expect(measurement.averageBicep, 34.5);
    });

    test('Average bicep with only one side', () {
      final rightOnly = BodyMeasurement(date: DateTime.now(), bicepRight: 35.0);
      expect(rightOnly.averageBicep, 35.0);

      final leftOnly = BodyMeasurement(date: DateTime.now(), bicepLeft: 34.0);
      expect(leftOnly.averageBicep, 34.0);
    });

    test('Average thigh calculation', () {
      final measurement = BodyMeasurement(
        date: DateTime.now(),
        thighRight: 55.0,
        thighLeft: 54.0,
      );

      expect(measurement.averageThigh, 54.5);
    });

    test('isComplete check - incomplete', () {
      final measurement = BodyMeasurement(date: DateTime.now(), weight: 75.0);

      expect(measurement.isComplete, false);
    });

    test('isComplete check - complete', () {
      final measurement = BodyMeasurement(
        date: DateTime.now(),
        weight: 75.0,
        waist: 85.0,
        chest: 100.0,
        hips: 95.0,
        bicepRight: 35.0,
        bicepLeft: 34.0,
        thighRight: 55.0,
        thighLeft: 54.0,
      );

      expect(measurement.isComplete, true);
    });

    test('toMap exports correctly', () {
      final measurement = BodyMeasurement(
        date: DateTime.now(),
        weight: 75.0,
        waist: 85.0,
      );

      final map = measurement.toMap();
      expect(map['weight'], 75.0);
      expect(map['waist'], 85.0);
      expect(map['chest'], null);
    });
  });

  group('ProgressTracker Model', () {
    late ProgressTracker tracker;

    setUp(() {
      tracker = ProgressTracker(
        measurements: [
          BodyMeasurement(
            date: DateTime(2026, 1, 1),
            weight: 80.0,
            waist: 90.0,
          ),
          BodyMeasurement(
            date: DateTime(2026, 1, 15),
            weight: 78.0,
            waist: 88.0,
          ),
          BodyMeasurement(
            date: DateTime(2026, 2, 1),
            weight: 76.0,
            waist: 85.0,
          ),
        ],
      );
    });

    test('Latest measurement', () {
      expect(tracker.latest?.weight, 76.0);
      expect(tracker.latest?.date.month, 2);
    });

    test('Oldest measurement', () {
      expect(tracker.oldest?.weight, 80.0);
      expect(tracker.oldest?.date.day, 1);
    });

    test('Total weight change', () {
      expect(tracker.totalWeightChange, -4.0);
    });

    test('Total waist change', () {
      expect(tracker.totalWaistChange, -5.0);
    });

    test('Total days', () {
      expect(tracker.totalDays, 31);
    });

    test('Total measurements', () {
      expect(tracker.totalMeasurements, 3);
    });

    test('Sorted by date', () {
      final sorted = tracker.sortedByDate;
      expect(sorted[0].weight, 80.0);
      expect(sorted[1].weight, 78.0);
      expect(sorted[2].weight, 76.0);
    });

    test('Weight at specific date', () {
      expect(tracker.weightAtDate(DateTime(2026, 1, 15)), 78.0);
      expect(tracker.weightAtDate(DateTime(2026, 1, 16)), null);
    });

    test('Empty tracker', () {
      final empty = ProgressTracker(measurements: []);

      expect(empty.latest, null);
      expect(empty.oldest, null);
      expect(empty.totalWeightChange, null);
      expect(empty.totalDays, 0);
    });
  });

  group('WeeklyStats Model', () {
    test('WeeklyStats creation', () {
      final stats = WeeklyStats(
        workoutsCompleted: 4,
        totalMinutes: 180,
        totalCaloriesBurned: 1200,
        streak: 7,
        avgWorkoutDuration: 45.0,
      );

      expect(stats.workoutsCompleted, 4);
      expect(stats.totalMinutes, 180);
      expect(stats.streak, 7);
    });

    test('Workout goal met (3+ workouts)', () {
      final metGoal = WeeklyStats(
        workoutsCompleted: 4,
        totalMinutes: 180,
        totalCaloriesBurned: 1200,
        streak: 7,
        avgWorkoutDuration: 45.0,
      );
      expect(metGoal.isWorkoutGoalMet, true);

      final notMet = WeeklyStats(
        workoutsCompleted: 2,
        totalMinutes: 90,
        totalCaloriesBurned: 600,
        streak: 2,
        avgWorkoutDuration: 45.0,
      );
      expect(notMet.isWorkoutGoalMet, false);
    });

    test('Time goal met (150+ minutes)', () {
      final metGoal = WeeklyStats(
        workoutsCompleted: 4,
        totalMinutes: 180,
        totalCaloriesBurned: 1200,
        streak: 7,
        avgWorkoutDuration: 45.0,
      );
      expect(metGoal.isTimeGoalMet, true);

      final notMet = WeeklyStats(
        workoutsCompleted: 2,
        totalMinutes: 90,
        totalCaloriesBurned: 600,
        streak: 2,
        avgWorkoutDuration: 45.0,
      );
      expect(notMet.isTimeGoalMet, false);
    });

    test('Compliance rate calculation', () {
      final full = WeeklyStats(
        workoutsCompleted: 5,
        totalMinutes: 225,
        totalCaloriesBurned: 1500,
        streak: 5,
        avgWorkoutDuration: 45.0,
      );
      expect(full.complianceRate, 1.0);

      final half = WeeklyStats(
        workoutsCompleted: 2,
        totalMinutes: 90,
        totalCaloriesBurned: 600,
        streak: 2,
        avgWorkoutDuration: 45.0,
      );
      expect(half.complianceRate, closeTo(0.4, 0.01));

      final over = WeeklyStats(
        workoutsCompleted: 7,
        totalMinutes: 315,
        totalCaloriesBurned: 2100,
        streak: 7,
        avgWorkoutDuration: 45.0,
      );
      expect(over.complianceRate, 1.0); // Capped at 100%
    });
  });
}
