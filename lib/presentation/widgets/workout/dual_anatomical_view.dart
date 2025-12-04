import 'package:flutter/material.dart';
import 'anatomical_muscle_view.dart';

class DualAnatomicalView extends StatelessWidget {
  final List<String> muscleGroups;
  final double height;
  final Color highlightColor;

  const DualAnatomicalView({
    super.key,
    required this.muscleGroups,
    this.height = 220,
    this.highlightColor = const Color(0xFFFF0000),
  });

  @override
  Widget build(BuildContext context) {
    return AnatomicalMuscleView(
      muscleGroups: muscleGroups,
      height: height,
      highlightColor: highlightColor,
    );
  }
}
