import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/workout_log_model.dart';

class WorkoutCalendarWidget extends StatefulWidget {
  final List<WorkoutLog> workoutLogs;

  const WorkoutCalendarWidget({super.key, required this.workoutLogs});

  @override
  State<WorkoutCalendarWidget> createState() => _WorkoutCalendarWidgetState();
}

class _WorkoutCalendarWidgetState extends State<WorkoutCalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
    });
  }

  bool _hasWorkoutOnDate(DateTime date) {
    return widget.workoutLogs.any((log) {
      final logDate = log.completedAt ?? log.startedAt;
      return logDate.year == date.year &&
          logDate.month == date.month &&
          logDate.day == date.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    // Adjust for starting on Monday
    final offsetDays = firstWeekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: AppTextStyles.h6,
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days of week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Text(
                    day,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + offsetDays,
            itemBuilder: (context, index) {
              if (index < offsetDays) {
                return const SizedBox.shrink();
              }

              final day = index - offsetDays + 1;
              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                day,
              );
              final hasWorkout = _hasWorkoutOnDate(date);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              return Container(
                decoration: BoxDecoration(
                  color: hasWorkout
                      ? AppColors.primaryNeon.withOpacity(0.2)
                      : isToday
                      ? AppColors.textSecondary.withOpacity(0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: AppColors.primaryNeon, width: 1)
                      : hasWorkout
                      ? Border.all(color: AppColors.primaryNeon, width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: hasWorkout
                          ? AppColors.primaryNeon
                          : AppColors.textPrimary,
                      fontWeight: hasWorkout || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
