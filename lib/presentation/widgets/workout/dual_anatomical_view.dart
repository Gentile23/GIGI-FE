import 'package:flutter/material.dart';
import 'anatomical_muscle_view.dart';

// Colori muscolari fissi — non modificabili dall'esterno
const Color _kPrimaryMuscleColor = Color(0xFFE53935); // Rosso acceso
const Color _kSecondaryMuscleColor = Color(0xFFEF9A9A); // Rosso chiaro

class DualAnatomicalView extends StatelessWidget {
  final List<String> muscleGroups;
  final List<String> secondaryMuscleGroups;
  final double height;
  // highlightColor mantenuto per retrocompatibilità ma ignorato internamente
  final Color highlightColor;

  const DualAnatomicalView({
    super.key,
    required this.muscleGroups,
    this.secondaryMuscleGroups = const [],
    this.height = 220,
    this.highlightColor = const Color(0xFFE53935),
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colorMap = {};

    // Muscoli secondari: rosso chiaro
    for (final muscle in secondaryMuscleGroups) {
      colorMap[muscle] = _kSecondaryMuscleColor;
    }

    // Muscoli primari: rosso acceso (sovrascrive eventuali secondari duplicati)
    for (final muscle in muscleGroups) {
      colorMap[muscle] = _kPrimaryMuscleColor;
    }

    return AnatomicalMuscleView(
      muscleGroups: muscleGroups,
      height: height,
      highlightColor: _kPrimaryMuscleColor,
      colorMap: colorMap,
    );
  }
}
