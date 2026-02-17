import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart' as xml;

import '../../../core/constants/muscle_groups.dart';

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
      // Load the SVG file
      String svgString = await rootBundle.loadString('assets/images/body.svg');

      // Parse XML
      final document = xml.XmlDocument.parse(svgString);

      // Map muscle groups to data-elem values
      // If colorMap is present, we use it directly. Otherwise we use muscleGroups + highlightColor

      final Map<String, Color> elementColors = {};

      if (widget.colorMap != null) {
        // Map based on the provided color map
        widget.colorMap!.forEach((group, color) {
          final elements = _mapMuscleGroupToElements(group);
          for (var elem in elements) {
            elementColors[elem] = color;
          }
        });
      } else {
        // Legacy mode: use muscleGroups and single highlightColor
        final elements = _mapMuscleGroupsToElements(widget.muscleGroups);
        for (var elem in elements) {
          elementColors[elem] = widget.highlightColor;
        }
      }

      // Modify SVG to highlight specific muscles
      _highlightMusclesInXml(document, elementColors);
      setState(() {
        _svgContent = document.toXmlString();
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading SVG: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  /// Maps database muscle group names to SVG data-elem values using precise matching
  Set<String> _mapMuscleGroupsToElements(List<String> groups) {
    final Set<String> elements = {};
    for (final group in groups) {
      elements.addAll(_mapMuscleGroupToElements(group));
    }
    return elements;
  }

  /// Maps a SINGLE group to its SVG elements
  List<String> _mapMuscleGroupToElements(String group) {
    // Strict mapping using the defined constants
    // This allows us to support the "Fixed Names" requested by the user
    // while maintaining some backward compatibility with common variations if needed.
    final Map<String, List<String>> muscleMap = {
      // Standard Fixed Names
      MuscleGroups.chest.toLowerCase(): ['CHEST'],
      MuscleGroups.back.toLowerCase(): ['BACK', 'TRAPS'],
      MuscleGroups.shoulders.toLowerCase(): ['SHOULDERS'],
      MuscleGroups.biceps.toLowerCase(): ['BICEPS'],
      MuscleGroups.triceps.toLowerCase(): ['TRICEPS'],
      MuscleGroups.forearms.toLowerCase(): ['FOREARMS'],
      MuscleGroups.abs.toLowerCase(): ['ABDOMINALS'],
      MuscleGroups.obliques.toLowerCase(): ['OBLIQUES'],
      MuscleGroups.quads.toLowerCase(): ['QUADRICEPS'],
      MuscleGroups.hamstrings.toLowerCase(): ['HAMSTRINGS'],
      MuscleGroups.glutes.toLowerCase(): ['GLUTES'],
      MuscleGroups.calves.toLowerCase(): ['CALVES'],
      MuscleGroups.traps.toLowerCase(): ['TRAPS'],
      'neck': ['TRAPS'], // Approximate
      // Common Variations (mapped to standard)
      'pectorals': ['CHEST'],
      'deltoids': ['SHOULDERS'],
      'lats': ['BACK'],
      'legs': ['QUADRICEPS', 'HAMSTRINGS', 'CALVES', 'GLUTES'],
      'core': ['ABDOMINALS', 'OBLIQUES'],
      'cardio': [
        'CHEST',
        'SHOULDERS',
        'BICEPS',
        'TRICEPS',
        'ABDOMINALS',
        'BACK',
        'QUADRICEPS',
        'HAMSTRINGS',
        'GLUTES',
        'CALVES',
      ],
      'full body': [
        'CHEST',
        'SHOULDERS',
        'BICEPS',
        'TRICEPS',
        'ABDOMINALS',
        'BACK',
        'QUADRICEPS',
        'HAMSTRINGS',
        'GLUTES',
        'CALVES',
      ],
      // Common exercise names (fallback for trial workout)
      'squat': ['QUADRICEPS', 'GLUTES', 'HAMSTRINGS'],
      'squats': ['QUADRICEPS', 'GLUTES', 'HAMSTRINGS'],
      'bodyweight squat': ['QUADRICEPS', 'GLUTES', 'HAMSTRINGS'],
      'push-up': ['CHEST', 'TRICEPS', 'SHOULDERS'],
      'pushup': ['CHEST', 'TRICEPS', 'SHOULDERS'],
      'push up': ['CHEST', 'TRICEPS', 'SHOULDERS'],
      'piegamenti': ['CHEST', 'TRICEPS', 'SHOULDERS'],
      'plank': ['ABDOMINALS', 'OBLIQUES'],
      'lunge': ['QUADRICEPS', 'GLUTES', 'HAMSTRINGS'],
      'lunges': ['QUADRICEPS', 'GLUTES', 'HAMSTRINGS'],
      'affondi': ['QUADRICEPS', 'GLUTES', 'HAMSTRINGS'],
      'crunch': ['ABDOMINALS'],
      'deadlift': ['BACK', 'HAMSTRINGS', 'GLUTES'],
      'row': ['BACK', 'BICEPS'],
      'rematore': ['BACK', 'BICEPS'],
      'curl': ['BICEPS'],
      'dip': ['TRICEPS', 'CHEST'],
      'bench press': ['CHEST', 'TRICEPS', 'SHOULDERS'],
      'panca': ['CHEST', 'TRICEPS', 'SHOULDERS'],
      'pull-up': ['BACK', 'BICEPS'],
      'trazioni': ['BACK', 'BICEPS'],
      'calf raise': ['CALVES'],
      'polpacci': ['CALVES'],
      'hip thrust': ['GLUTES', 'HAMSTRINGS'],
      'glute bridge': ['GLUTES', 'HAMSTRINGS'],
      'side plank': ['OBLIQUES', 'ABDOMINALS'],
      'mountain climber': ['ABDOMINALS', 'QUADRICEPS'],
      'burpee': ['CHEST', 'QUADRICEPS', 'SHOULDERS', 'ABDOMINALS'],
    };

    final normalizedGroup = group.toLowerCase().trim();

    // 1. Try Exact Match
    if (muscleMap.containsKey(normalizedGroup)) {
      return muscleMap[normalizedGroup]!;
    }

    // 2. Partial match fallback
    for (final key in muscleMap.keys) {
      if (normalizedGroup.contains(key)) {
        return muscleMap[key]!;
      }
    }

    return [];
  }

  /// Modifies XML document to highlight specific muscle groups with specific colors
  void _highlightMusclesInXml(
    xml.XmlDocument document,
    Map<String, Color> elementColors,
  ) {
    // Find all elements with data-elem attribute
    final allElements = document.findAllElements('*');

    for (final element in allElements) {
      final dataElem = element.getAttribute('data-elem');

      if (dataElem != null) {
        // First, set all muscles to white with black borders
        element.setAttribute('fill', '#FFFFFF');
        element.setAttribute('stroke', '#000000');
        element.setAttribute('stroke-width', '1');
        element.setAttribute('opacity', '1');

        // Then, if this muscle should be highlighted, apply the highlight color
        if (elementColors.containsKey(dataElem)) {
          final color = elementColors[dataElem]!;
          final hex = '#${color.toARGB32().toRadixString(16).substring(2, 8)}';
          element.setAttribute('fill', hex);
          // Use the actual color opacity instead of a hardcoded value
          element.setAttribute('opacity', color.a.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show fallback when SVG fails to load
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
