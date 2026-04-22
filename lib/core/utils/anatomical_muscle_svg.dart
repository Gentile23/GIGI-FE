import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;

class AnatomicalMuscleSvg {
  static const String assetPath = 'assets/images/body.svg';
  static const Size viewBoxSize = Size(535, 462);

  static String? _cachedSvgString;

  static final RegExp _pathTokenPattern = RegExp(
    r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?',
  );

  static Future<String> buildHighlightedSvg({
    List<String> muscleGroups = const [],
    Color highlightColor = const Color(0xFFFF0000),
    Map<String, Color>? colorMap,
  }) async {
    final svgString = await _loadSvgString();
    final document = xml.XmlDocument.parse(svgString);
    final elementColors = <String, Color>{};

    if (colorMap != null) {
      colorMap.forEach((group, color) {
        for (final element in mapMuscleGroupToElements(group)) {
          elementColors[element] = color;
        }
      });
    } else {
      for (final element in mapMuscleGroupsToElements(muscleGroups)) {
        elementColors[element] = highlightColor;
      }
    }

    highlightMusclesInXml(document, elementColors);
    return document.toXmlString();
  }

  static Future<String?> buildHighlightedPngBase64({
    required List<String> primaryMuscleGroups,
    required List<String> secondaryMuscleGroups,
    int width = 160,
    int height = 138,
  }) async {
    try {
      final svgString = await buildHighlightedSvg(
        colorMap: {
          for (final group in secondaryMuscleGroups)
            group: const Color(0xFFFF9A9A),
          for (final group in primaryMuscleGroups)
            group: const Color(0xFFE53935),
        },
      );

      final pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );
      try {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final sourceSize = pictureInfo.size;
        final scale = math.min(
          width / sourceSize.width,
          height / sourceSize.height,
        );
        final dx = (width - sourceSize.width * scale) / 2;
        final dy = (height - sourceSize.height * scale) / 2;

        canvas.translate(dx, dy);
        canvas.scale(scale);
        canvas.drawPicture(pictureInfo.picture);

        final image = await recorder.endRecording().toImage(width, height);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          if (bytes == null) return null;
          return base64Encode(bytes.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      } finally {
        pictureInfo.picture.dispose();
      }
    } catch (e) {
      debugPrint('Unable to render anatomical PNG for lock screen: $e');
      return null;
    }
  }

  static Set<String> mapMuscleGroupsToElements(List<String> groups) {
    final elements = <String>{};
    for (final group in groups) {
      elements.addAll(mapMuscleGroupToElements(group));
    }
    return elements;
  }

  static List<String> mapMuscleGroupToElements(String group) {
    var suffix = '';
    var normalizedGroup = group.toUpperCase().trim();

    if (normalizedGroup.endsWith('_LEFT')) {
      suffix = '_LEFT';
      normalizedGroup = normalizedGroup.substring(
        0,
        normalizedGroup.length - 5,
      );
    } else if (normalizedGroup.endsWith('_RIGHT')) {
      suffix = '_RIGHT';
      normalizedGroup = normalizedGroup.substring(
        0,
        normalizedGroup.length - 6,
      );
    }

    const muscleMap = {
      'chest': ['CHEST'],
      'traps': ['TRAPS'],
      'back': ['BACK'],
      'shoulders': ['SHOULDERS'],
      'biceps': ['BICEPS'],
      'triceps': ['TRICEPS'],
      'forearms': ['FOREARMS'],
      'abs': ['ABDOMINALS'],
      'abdominals': ['ABDOMINALS'],
      'obliques': ['OBLIQUES'],
      'quads': ['QUADRICEPS'],
      'quadriceps': ['QUADRICEPS'],
      'hamstrings': ['HAMSTRINGS'],
      'glutes': ['GLUTES'],
      'calves': ['CALVES'],
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
    List<String> results = const [];

    if (muscleMap.containsKey(query)) {
      results = muscleMap[query]!;
    } else {
      for (final key in muscleMap.keys) {
        if (query.contains(key)) {
          results = muscleMap[key]!;
          break;
        }
      }
    }

    if (suffix.isEmpty) return results;
    return results.map((element) => element + suffix).toList();
  }

  static void highlightMusclesInXml(
    xml.XmlDocument document,
    Map<String, Color> elementColors,
  ) {
    final svgCenter = viewBoxSize.width / 2;

    for (final element in document.findAllElements('*')) {
      final dataElem = element.getAttribute('data-elem');
      if (dataElem == null) continue;

      element.setAttribute('fill', '#FFFFFF');
      element.setAttribute('stroke', '#000000');
      element.setAttribute('stroke-width', '1');
      element.setAttribute('opacity', '1');

      final pathData = element.getAttribute('d') ?? '';
      final side = _estimateAnatomicalSide(pathData, svgCenter: svgCenter);
      final isLeft = side == _AnatomicalSide.left;
      final isRight = side == _AnatomicalSide.right;

      Color? selectedColor;
      if (isLeft && elementColors.containsKey('${dataElem}_LEFT')) {
        selectedColor = elementColors['${dataElem}_LEFT'];
      } else if (isRight && elementColors.containsKey('${dataElem}_RIGHT')) {
        selectedColor = elementColors['${dataElem}_RIGHT'];
      } else if (elementColors.containsKey(dataElem)) {
        selectedColor = elementColors[dataElem];
      }

      if (selectedColor != null) {
        final hex =
            '#${selectedColor.toARGB32().toRadixString(16).substring(2, 8)}';
        element.setAttribute('fill', hex);
        element.setAttribute('opacity', selectedColor.a.toString());
      }
    }
  }

  static Future<String> _loadSvgString() async {
    final cached = _cachedSvgString;
    if (cached != null) return cached;
    final svgString = await rootBundle.loadString(assetPath);
    _cachedSvgString = svgString;
    return svgString;
  }

  static _AnatomicalSide? _estimateAnatomicalSide(
    String pathData, {
    required double svgCenter,
  }) {
    final xCoordinates = _extractPathXCoordinates(pathData);
    if (xCoordinates.isEmpty) return null;

    final minX = xCoordinates.reduce(math.min);
    final maxX = xCoordinates.reduce(math.max);
    final pathCenterX = (minX + maxX) / 2;

    if (pathCenterX < svgCenter) {
      const frontMidline = 115.0;
      if (pathCenterX < frontMidline - 5) return _AnatomicalSide.right;
      if (pathCenterX > frontMidline + 5) return _AnatomicalSide.left;
    } else {
      const backMidline = 411.0;
      if (pathCenterX < backMidline - 5) return _AnatomicalSide.left;
      if (pathCenterX > backMidline + 5) return _AnatomicalSide.right;
    }

    return null;
  }

  static List<double> _extractPathXCoordinates(String pathData) {
    final tokens = _pathTokenPattern
        .allMatches(pathData)
        .map((match) => match.group(0)!)
        .toList();
    final coordinates = <double>[];
    var command = '';
    var currentX = 0.0;
    var currentY = 0.0;
    var subpathStartX = 0.0;
    var subpathStartY = 0.0;

    for (var i = 0; i < tokens.length;) {
      final token = tokens[i];
      if (_isSvgPathCommand(token)) {
        command = token;
        i++;

        if (command == 'Z' || command == 'z') {
          currentX = subpathStartX;
          currentY = subpathStartY;
          continue;
        }
      }

      final segmentLength = _pathCommandSegmentLength(command);
      if (segmentLength == 0 || i + segmentLength > tokens.length) break;

      final segment = tokens
          .skip(i)
          .take(segmentLength)
          .map(double.tryParse)
          .toList();
      if (segment.any((value) => value == null)) break;

      final values = segment.cast<double>();
      final isRelative = command == command.toLowerCase();

      switch (command.toUpperCase()) {
        case 'M':
          final x = _absoluteX(values[0], currentX, isRelative);
          final y = _absoluteY(values[1], currentY, isRelative);
          coordinates.add(x);
          currentX = x;
          currentY = y;
          subpathStartX = x;
          subpathStartY = y;
          command = isRelative ? 'l' : 'L';
          break;
        case 'L':
        case 'T':
          final x = _absoluteX(values[0], currentX, isRelative);
          coordinates.add(x);
          currentX = x;
          currentY = _absoluteY(values[1], currentY, isRelative);
          break;
        case 'H':
          final x = _absoluteX(values[0], currentX, isRelative);
          coordinates.add(x);
          currentX = x;
          break;
        case 'V':
          currentY = _absoluteY(values[0], currentY, isRelative);
          break;
        case 'C':
          coordinates
            ..add(_absoluteX(values[0], currentX, isRelative))
            ..add(_absoluteX(values[2], currentX, isRelative))
            ..add(_absoluteX(values[4], currentX, isRelative));
          currentX = _absoluteX(values[4], currentX, isRelative);
          currentY = _absoluteY(values[5], currentY, isRelative);
          break;
        case 'S':
        case 'Q':
          coordinates
            ..add(_absoluteX(values[0], currentX, isRelative))
            ..add(_absoluteX(values[2], currentX, isRelative));
          currentX = _absoluteX(values[2], currentX, isRelative);
          currentY = _absoluteY(values[3], currentY, isRelative);
          break;
        case 'A':
          final x = _absoluteX(values[5], currentX, isRelative);
          coordinates.add(x);
          currentX = x;
          currentY = _absoluteY(values[6], currentY, isRelative);
          break;
      }

      i += segmentLength;
    }

    return coordinates;
  }

  static bool _isSvgPathCommand(String token) {
    return token.length == 1 && RegExp(r'[A-Za-z]').hasMatch(token);
  }

  static int _pathCommandSegmentLength(String command) {
    switch (command.toUpperCase()) {
      case 'M':
      case 'L':
      case 'T':
        return 2;
      case 'H':
      case 'V':
        return 1;
      case 'C':
        return 6;
      case 'S':
      case 'Q':
        return 4;
      case 'A':
        return 7;
      default:
        return 0;
    }
  }

  static double _absoluteX(double value, double currentX, bool isRelative) {
    return isRelative ? currentX + value : value;
  }

  static double _absoluteY(double value, double currentY, bool isRelative) {
    return isRelative ? currentY + value : value;
  }
}

enum _AnatomicalSide { left, right }
