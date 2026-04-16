import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart' as xml;

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

  static String? _cachedSvgString;

  Future<void> _loadAndModifySvg() async {
    try {
      // Load the SVG file
      String svgString;
      if (_cachedSvgString != null) {
        svgString = _cachedSvgString!;
      } else {
        svgString = await rootBundle.loadString('assets/images/body.svg');
        _cachedSvgString = svgString;
      }

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
      if (mounted) {
        setState(() {
          _svgContent = document.toXmlString();
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
    // Check for side suffixes
    String suffix = '';
    String normalizedGroup = group.toUpperCase().trim();
    
    if (normalizedGroup.endsWith('_LEFT')) {
      suffix = '_LEFT';
      normalizedGroup = normalizedGroup.substring(0, normalizedGroup.length - 5);
    } else if (normalizedGroup.endsWith('_RIGHT')) {
      suffix = '_RIGHT';
      normalizedGroup = normalizedGroup.substring(0, normalizedGroup.length - 6);
    }

    // Strict mapping using the defined constants
    // This allows us to support the "Fixed Names" requested by the user
    // while maintaining some backward compatibility with common variations if needed.
    final Map<String, List<String>> muscleMap = {
      // Standard Fixed Names (Direct matches)
      'chest': ['CHEST'],
      'back': ['BACK'],
      'shoulders': ['SHOULDERS'],
      'biceps': ['BICEPS'],
      'triceps': ['TRICEPS'],
      'forearms': ['FOREARMS'],
      'abs': ['ABDOMINALS'],
      'abdominals': ['ABDOMINALS'],
      'obliques': ['OBLIQUES'],
      'quads': ['QUADRICEPS'],
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

    final query = normalizedGroup.toLowerCase();
    List<String> results = [];

    // 1. Try Exact Match
    if (muscleMap.containsKey(query)) {
      results = muscleMap[query]!;
    } else {
      // 2. Partial match fallback
      for (final key in muscleMap.keys) {
        if (query.contains(key)) {
          results = muscleMap[key]!;
          break;
        }
      }
    }

    if (suffix.isEmpty) return results;
    return results.map((e) => e + suffix).toList();
  }

  /// Modifies XML document to highlight specific muscle groups with specific colors
  void _highlightMusclesInXml(
    xml.XmlDocument document,
    Map<String, Color> elementColors,
  ) {
    // Find all elements with data-elem attribute
    final allElements = document.findAllElements('*');
    const double svgCenter = 535 / 2; // Fixed width of body.svg is 535

    for (final element in allElements) {
      final dataElem = element.getAttribute('data-elem');

      if (dataElem != null) {
        // First, set all muscles to white with black borders
        element.setAttribute('fill', '#FFFFFF');
        element.setAttribute('stroke', '#000000');
        element.setAttribute('stroke-width', '1');
        element.setAttribute('opacity', '1');

        // Determine the side of the path based on its coordinates
        final pathData = element.getAttribute('d') ?? '';
        bool isLeft = false;
        bool isRight = false;
        
        // Heuristic: determine side based on view (Front/Back) and midline
        final match = RegExp(r'[Mm]\s+([\d.]+)').firstMatch(pathData);
        if (match != null) {
          final x = double.tryParse(match.group(1)!) ?? svgCenter;
          
          if (x < svgCenter) {
            // Front View: 
            // Viewer Left (x > frontMidline) is Anatomical Right
            // Viewer Right (x < frontMidline) is Anatomical Left
            // Front View: midline = 115
            // Viewer Left (x < midline) is Anatomical Right
            // Viewer Right (x > midline) is Anatomical Left
            const double frontMidline = 115.0;
            if (x < frontMidline - 5) {
              isRight = true;
            } else if (x > frontMidline + 5) {
              isLeft = true;
            }
          } else {
            // Back View: midline = 411
            // Viewer Left (x < midline) is Anatomical Left
            // Viewer Right (x > midline) is Anatomical Right
            const double backMidline = 411.0;
            if (x < backMidline - 5) {
              isLeft = true;
            } else if (x > backMidline + 5) {
              isRight = true;
            }
          }
        }

        // Selection logic for colors
        Color? selectedColor;
        
        if (isLeft && elementColors.containsKey('${dataElem}_LEFT')) {
          selectedColor = elementColors['${dataElem}_LEFT'];
        } else if (isRight && elementColors.containsKey('${dataElem}_RIGHT')) {
          selectedColor = elementColors['${dataElem}_RIGHT'];
        } else if (elementColors.containsKey(dataElem)) {
          selectedColor = elementColors[dataElem];
        }

        if (selectedColor != null) {
          final hex = '#${selectedColor.toARGB32().toRadixString(16).substring(2, 8)}';
          element.setAttribute('fill', hex);
          element.setAttribute('opacity', selectedColor.a.toString());
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
