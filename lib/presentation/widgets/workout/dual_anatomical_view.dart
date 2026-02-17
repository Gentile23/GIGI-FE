import 'package:flutter/material.dart';
import 'anatomical_muscle_view.dart';

class DualAnatomicalView extends StatelessWidget {
  final List<String> muscleGroups;
  final List<String> secondaryMuscleGroups;
  final double height;
  final Color highlightColor;

  const DualAnatomicalView({
    super.key,
    required this.muscleGroups,
    this.secondaryMuscleGroups = const [],
    this.height = 220,
    this.highlightColor = const Color(0xFFFF0000),
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colorMap = {};

    // Secondary muscles: Very light faded red
    // Using 0.1 opacity for small images as requested (super chiaro)
    for (final muscle in secondaryMuscleGroups) {
      colorMap[muscle] = highlightColor.withValues(alpha: 0.1);
    }

    // Primary muscles: Bright red
    for (final muscle in muscleGroups) {
      colorMap[muscle] = highlightColor;
    }

    return AnatomicalMuscleView(
      muscleGroups: muscleGroups,
      height: height,
      highlightColor: highlightColor,
      colorMap: colorMap,
    );
  }
}
