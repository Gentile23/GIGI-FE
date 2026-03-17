import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../workout/anatomical_muscle_view.dart';

/// Interactive body silhouette widget that shows body measurements
/// with color-coded areas based on progress
class InteractiveBodySilhouette extends StatefulWidget {
  final Map<String, dynamic>? measurements;
  final Map<String, dynamic>? changes;
  final Function(String bodyPart)? onBodyPartTap;
  final bool showFront;

  const InteractiveBodySilhouette({
    super.key,
    this.measurements,
    this.changes,
    this.onBodyPartTap,
    this.showFront = true,
  });

  @override
  State<InteractiveBodySilhouette> createState() =>
      _InteractiveBodySilhouetteState();
}

class _InteractiveBodySilhouetteState extends State<InteractiveBodySilhouette> {
  String? _selectedPart;

  Map<String, Color> _buildColorMap() {
    final Map<String, Color> colorMap = {};
    final changes = widget.changes ?? {};

    // Mapping helper
    void mapChange(String key, List<String> muscles, {bool isWaist = false}) {
      if (changes.containsKey(key)) {
        final change = changes[key] as num;
        final color = _getColorForChange(change, isWaist: isWaist);
        for (var m in muscles) {
          colorMap[m] = color;
        }
      }
    }

    mapChange('neck_cm', ['TRAPS']);
    mapChange('shoulders_cm', ['SHOULDERS']);
    mapChange('chest_cm', ['CHEST']);
    mapChange('bicep_left_cm', ['BICEPS_LEFT']);
    mapChange('bicep_right_cm', ['BICEPS_RIGHT']);
    mapChange('forearm_cm', ['FOREARMS']);
    mapChange('waist_cm', ['ABDOMINALS', 'OBLIQUES'], isWaist: true);
    mapChange('hips_cm', ['GLUTES']); // Approx
    mapChange('thigh_left_cm', ['QUADRICEPS_LEFT', 'HAMSTRINGS_LEFT']);
    mapChange('thigh_right_cm', ['QUADRICEPS_RIGHT', 'HAMSTRINGS_RIGHT']);
    mapChange('calf_cm', ['CALVES']);

    return colorMap;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle front/back
        Row(mainAxisAlignment: MainAxisAlignment.center),
        const SizedBox(height: 16),

        // Body silhouette
        SizedBox(
          height: 400,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Body SVG with highlighting
              AnatomicalMuscleView(
                height: 380,
                muscleGroups: const [], // Using colorMap instead
                colorMap: _buildColorMap(),
              ),

              // Body parts overlay removed - SVG handles coloring

              // Measurement labels
              ..._buildMeasurementLabels(),
            ],
          ),
        ),

        // Legend
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildBodyPartCircle({
    required double top,
    required double left,
    required double size,
    required String partId,
    required String label,
    num? change,
  }) {
    final isSelected = _selectedPart == partId;
    final color = _getColorForChange(change, isHead: partId == 'head');

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () {
          setState(
            () => _selectedPart = _selectedPart == partId ? null : partId,
          );
          widget.onBodyPartTap?.call(partId);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.9 : 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : color,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBodyPartRect({
    required double top,
    required double left,
    required double width,
    required double height,
    required String partId,
    required String label,
    num? change,
    double borderRadius = 8,
    bool isWaist = false,
  }) {
    final isSelected = _selectedPart == partId;
    final color = _getColorForChange(change, isWaist: isWaist);
    final measurement = widget.measurements?[partId];

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () {
          setState(
            () => _selectedPart = _selectedPart == partId ? null : partId,
          );
          widget.onBodyPartTap?.call(partId);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.9 : 0.6),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSelected ? Colors.white : color,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: measurement != null
                ? Text(
                    '$measurement',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: width > 50 ? 12 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Color _getColorForChange(
    num? change, {
    bool isWaist = false,
    bool isHead = false,
  }) {
    if (isHead) return CleanTheme.textSecondary;
    if (change == null) return CleanTheme.borderSecondary;
    if (change == 0) return CleanTheme.accentBlue;

    // For waist, decrease is good
    if (isWaist) {
      if (change < 0) return CleanTheme.accentGreen;
      return CleanTheme.accentRed;
    }

    // For muscles, increase is good
    if (change > 0) return CleanTheme.accentGreen;
    return CleanTheme.accentRed;
  }

  List<Widget> _buildMeasurementLabels() {
    return [
      // Upper Body
      _buildHotspot(top: 40, left: 185, size: 30, partId: 'neck_cm'),
      _buildHotspot(top: 70, left: 140, width: 120, height: 40, partId: 'shoulders_cm'),
      _buildHotspot(top: 100, left: 160, width: 80, height: 50, partId: 'chest_cm'),
      
      // Arms
      _buildHotspot(top: 110, left: 125, size: 40, partId: 'bicep_left_cm'),
      _buildHotspot(top: 110, left: 235, size: 40, partId: 'bicep_right_cm'),
      
      // Mid Section
      _buildHotspot(top: 155, left: 165, width: 70, height: 60, partId: 'waist_cm'),
      _buildHotspot(top: 215, left: 165, width: 70, height: 40, partId: 'hips_cm'),
      
      // Legs
      _buildHotspot(top: 260, left: 150, width: 45, height: 80, partId: 'thigh_left_cm'),
      _buildHotspot(top: 260, left: 205, width: 45, height: 80, partId: 'thigh_right_cm'),
      _buildHotspot(top: 350, left: 155, width: 40, height: 30, partId: 'calf_cm'),
      _buildHotspot(top: 350, left: 205, width: 40, height: 30, partId: 'calf_cm'),
    ];
  }

  Widget _buildHotspot({
    required double top,
    required double left,
    double? size,
    double? width,
    double? height,
    required String partId,
  }) {
    final isSelected = _selectedPart == partId;
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('Tapped hotspot: $partId');
          final hasData = widget.measurements?[partId] != null || 
                         (widget.changes != null && widget.changes![partId] != null);

          if (!hasData) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Non abbiamo ancora dati per questo gruppo muscolare. Inserisci una misura per iniziare!',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                backgroundColor: CleanTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            return;
          }

          setState(() {
            _selectedPart = (_selectedPart == partId) ? null : partId;
          });
          widget.onBodyPartTap?.call(partId);
        },
        child: Container(
          width: size ?? width,
          height: size ?? height,
          decoration: BoxDecoration(
            color: isSelected ? CleanTheme.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(size != null ? size / 2 : 8),
            border: isSelected ? Border.all(color: CleanTheme.primaryColor, width: 2) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Crescita', CleanTheme.accentGreen),
          _buildLegendItem('Stabile', CleanTheme.accentBlue),
          _buildLegendItem('Riduzione', CleanTheme.accentRed),
          _buildLegendItem('No dati', CleanTheme.borderSecondary),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
