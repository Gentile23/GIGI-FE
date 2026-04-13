import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_log_model.dart';

class WorkoutCalendarWidget extends StatefulWidget {
  final List<WorkoutLog> workoutLogs;
  final bool showLegend;
  final bool showMonthlyCount;

  const WorkoutCalendarWidget({
    super.key,
    required this.workoutLogs,
    this.showLegend = false,
    this.showMonthlyCount = false,
  });

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

  int _workoutsOnDate(DateTime date) {
    return widget.workoutLogs.where((log) {
      final logDate = log.completedAt ?? log.startedAt;
      return logDate.year == date.year &&
          logDate.month == date.month &&
          logDate.day == date.day;
    }).length;
  }

  int _focusedMonthWorkoutCount() {
    return widget.workoutLogs.where((log) {
      final logDate = log.completedAt ?? log.startedAt;
      return logDate.year == _focusedMonth.year &&
          logDate.month == _focusedMonth.month;
    }).length;
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
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
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
                  color: CleanTheme.textPrimary,
                ),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy', 'it').format(_focusedMonth),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: CleanTheme.textPrimary,
                ),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          if (widget.showMonthlyCount) ...[
            const SizedBox(height: 6),
            Text(
              '${_focusedMonthWorkoutCount()} allenamenti nel mese',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CleanTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Days of week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom']
                .map(
                  (day) => Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textSecondary,
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
              final workoutsCount = _workoutsOnDate(date);
              final hasWorkout = workoutsCount > 0;
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final intensityAlpha = workoutsCount >= 2 ? 0.24 : 0.15;

              return Container(
                decoration: BoxDecoration(
                  color: hasWorkout
                      ? CleanTheme.primaryColor.withValues(
                          alpha: intensityAlpha,
                        )
                      : isToday
                      ? CleanTheme.textSecondary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: CleanTheme.primaryColor, width: 1.5)
                      : hasWorkout
                      ? Border.all(color: CleanTheme.primaryColor, width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: hasWorkout
                          ? CleanTheme.primaryColor
                          : CleanTheme.textPrimary,
                      fontWeight: (hasWorkout && workoutsCount >= 2) || isToday
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.showLegend) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.15),
                  label: 'Allenato',
                ),
                const SizedBox(width: 14),
                _buildLegendDot(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.24),
                  label: '2+ sessioni',
                ),
                const SizedBox(width: 14),
                _buildLegendDot(
                  color: CleanTheme.textSecondary.withValues(alpha: 0.1),
                  label: 'Oggi',
                  borderColor: CleanTheme.primaryColor,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot({
    required Color color,
    required String label,
    Color? borderColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: CleanTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
