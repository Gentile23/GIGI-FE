import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/utils/anatomical_muscle_svg.dart';

class AnatomicalMuscleView extends StatefulWidget {
  final List<String> muscleGroups;
  final double height;
  final Color highlightColor;
  final Map<String, Color>? colorMap;

  const AnatomicalMuscleView({
    super.key,
    required this.muscleGroups,
    this.height = 200,
    this.highlightColor = const Color(0xFFFF0000),
    this.colorMap,
  });

  @override
  State<AnatomicalMuscleView> createState() => _AnatomicalMuscleViewState();
}

class _AnatomicalMuscleViewState extends State<AnatomicalMuscleView> {
  String? _svgContent;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAndModifySvg();
  }

  @override
  void didUpdateWidget(AnatomicalMuscleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muscleGroups != widget.muscleGroups ||
        oldWidget.highlightColor != widget.highlightColor ||
        oldWidget.colorMap != widget.colorMap) {
      _loadAndModifySvg();
    }
  }

  Future<void> _loadAndModifySvg() async {
    try {
      final svgContent = await AnatomicalMuscleSvg.buildHighlightedSvg(
        muscleGroups: widget.muscleGroups,
        highlightColor: widget.highlightColor,
        colorMap: widget.colorMap,
      );
      if (mounted) {
        setState(() {
          _svgContent = svgContent;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading SVG: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 48, color: widget.highlightColor),
            const SizedBox(height: 8),
            Text(
              widget.muscleGroups.join(', '),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.highlightColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_svgContent == null) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Center(
        child: SvgPicture.string(
          _svgContent!,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
