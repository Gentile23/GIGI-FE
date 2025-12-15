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
    mapChange('bicep_left_cm', ['BICEPS']);
    mapChange('bicep_right_cm', ['BICEPS']);
    mapChange('forearm_cm', ['FOREARMS']);
    mapChange('waist_cm', ['ABDOMINALS', 'OBLIQUES'], isWaist: true);
    mapChange('hips_cm', ['GLUTES']); // Approx
    mapChange('thigh_left_cm', ['QUADRICEPS', 'HAMSTRINGS']);
    mapChange('thigh_right_cm', ['QUADRICEPS', 'HAMSTRINGS']);
    mapChange('calf_cm', ['CALVES']);

    return colorMap;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle front/back
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.showFront ? '👤 Vista Frontale' : '👤 Vista Posteriore',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Body silhouette
        SizedBox(
          height: 400,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Body outline
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

        // Selected part info
        if (_selectedPart != null) ...[
          const SizedBox(height: 16),
          _buildSelectedPartInfo(),
        ],
      ],
    );
  }

  List<Widget> _buildBodyParts() {
    final parts = <Widget>[];
    final changes = widget.changes ?? {};

    // Head
    parts.add(
      _buildBodyPartCircle(
        top: 0,
        left: 75,
        size: 50,
        partId: 'head',
        label: 'Testa',
      ),
    );

    // Neck
    parts.add(
      _buildBodyPartRect(
        top: 50,
        left: 88,
        width: 24,
        height: 15,
        partId: 'neck_cm',
        label: 'Collo',
        change: changes['neck_cm'] as num?,
      ),
    );

    // Shoulders
    parts.add(
      _buildBodyPartRect(
        top: 62,
        left: 40,
        width: 120,
        height: 20,
        partId: 'shoulders_cm',
        label: 'Spalle',
        change: changes['shoulders_cm'] as num?,
        borderRadius: 10,
      ),
    );

    // Chest
    parts.add(
      _buildBodyPartRect(
        top: 80,
        left: 55,
        width: 90,
        height: 50,
        partId: 'chest_cm',
        label: 'Petto',
        change: changes['chest_cm'] as num?,
        borderRadius: 20,
      ),
    );

    // Left Bicep
    parts.add(
      _buildBodyPartRect(
        top: 75,
        left: 15,
        width: 30,
        height: 50,
        partId: 'bicep_left_cm',
        label: 'Bicipite SX',
        change: changes['bicep_left_cm'] as num?,
        borderRadius: 12,
      ),
    );

    // Right Bicep
    parts.add(
      _buildBodyPartRect(
        top: 75,
        left: 155,
        width: 30,
        height: 50,
        partId: 'bicep_right_cm',
        label: 'Bicipite DX',
        change: changes['bicep_right_cm'] as num?,
        borderRadius: 12,
      ),
    );

    // Left Forearm
    parts.add(
      _buildBodyPartRect(
        top: 125,
        left: 5,
        width: 25,
        height: 45,
        partId: 'forearm_left_cm',
        label: 'Avambraccio SX',
        change: changes['forearm_cm'] as num?,
        borderRadius: 8,
      ),
    );

    // Right Forearm
    parts.add(
      _buildBodyPartRect(
        top: 125,
        left: 170,
        width: 25,
        height: 45,
        partId: 'forearm_right_cm',
        label: 'Avambraccio DX',
        change: changes['forearm_cm'] as num?,
        borderRadius: 8,
      ),
    );

    // Waist
    parts.add(
      _buildBodyPartRect(
        top: 130,
        left: 60,
        width: 80,
        height: 35,
        partId: 'waist_cm',
        label: 'Vita',
        change: changes['waist_cm'] as num?,
        isWaist: true,
        borderRadius: 15,
      ),
    );

    // Hips
    parts.add(
      _buildBodyPartRect(
        top: 165,
        left: 50,
        width: 100,
        height: 35,
        partId: 'hips_cm',
        label: 'Fianchi',
        change: changes['hips_cm'] as num?,
        borderRadius: 20,
      ),
    );

    // Left Thigh
    parts.add(
      _buildBodyPartRect(
        top: 200,
        left: 55,
        width: 40,
        height: 80,
        partId: 'thigh_left_cm',
        label: 'Coscia SX',
        change: changes['thigh_left_cm'] as num?,
        borderRadius: 15,
      ),
    );

    // Right Thigh
    parts.add(
      _buildBodyPartRect(
        top: 200,
        left: 105,
        width: 40,
        height: 80,
        partId: 'thigh_right_cm',
        label: 'Coscia DX',
        change: changes['thigh_right_cm'] as num?,
        borderRadius: 15,
      ),
    );

    // Left Calf
    parts.add(
      _buildBodyPartRect(
        top: 285,
        left: 60,
        width: 30,
        height: 60,
        partId: 'calf_left_cm',
        label: 'Polpaccio SX',
        change: changes['calf_cm'] as num?,
        borderRadius: 10,
      ),
    );

    // Right Calf
    parts.add(
      _buildBodyPartRect(
        top: 285,
        left: 110,
        width: 30,
        height: 60,
        partId: 'calf_right_cm',
        label: 'Polpaccio DX',
        change: changes['calf_cm'] as num?,
        borderRadius: 10,
      ),
    );

    return parts;
  }

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

    // For waist, decrease is good
    if (isWaist) {
      if (change < -2) return CleanTheme.accentGreen;
      if (change < 0) return CleanTheme.accentGreen.withValues(alpha: 0.7);
      if (change > 2) return CleanTheme.accentRed;
      if (change > 0) return CleanTheme.accentRed.withValues(alpha: 0.7);
      return CleanTheme.accentBlue;
    }

    // For muscles, increase is good
    if (change > 1) return CleanTheme.accentGreen;
    if (change > 0) return CleanTheme.accentGreen.withValues(alpha: 0.7);
    if (change < -1) return CleanTheme.accentRed;
    if (change < 0) return CleanTheme.accentRed.withValues(alpha: 0.7);
    return CleanTheme.accentBlue;
  }

  List<Widget> _buildMeasurementLabels() {
    return [];
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
          _buildLegendItem('📈 Crescita', CleanTheme.accentGreen),
          _buildLegendItem('➡️ Stabile', CleanTheme.accentBlue),
          _buildLegendItem('📉 Riduzione', CleanTheme.accentRed),
          _buildLegendItem('❓ No dati', CleanTheme.borderSecondary),
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

  Widget _buildSelectedPartInfo() {
    final partLabels = {
      'head': ('Testa', null),
      'neck_cm': ('Collo', '🦒'),
      'shoulders_cm': ('Spalle', '🏋️'),
      'chest_cm': ('Petto', '👕'),
      'bicep_left_cm': ('Bicipite SX', '💪'),
      'bicep_right_cm': ('Bicipite DX', '💪'),
      'forearm_left_cm': ('Avambraccio SX', '💪'),
      'forearm_right_cm': ('Avambraccio DX', '💪'),
      'waist_cm': ('Vita', '⭕'),
      'hips_cm': ('Fianchi', '🍑'),
      'thigh_left_cm': ('Coscia SX', '🦵'),
      'thigh_right_cm': ('Coscia DX', '🦵'),
      'calf_left_cm': ('Polpaccio SX', '🦶'),
      'calf_right_cm': ('Polpaccio DX', '🦶'),
    };

    final partInfo = partLabels[_selectedPart];
    if (partInfo == null) return const SizedBox.shrink();

    final measurement = widget.measurements?[_selectedPart];
    final change = widget.changes?[_selectedPart] as num?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (partInfo.$2 != null)
                Text(partInfo.$2!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                partInfo.$1,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                'Attuale',
                measurement != null ? '$measurement cm' : '-',
                CleanTheme.primaryColor,
              ),
              if (change != null)
                _buildInfoItem(
                  'Variazione',
                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} cm',
                  change > 0 ? CleanTheme.accentGreen : CleanTheme.accentRed,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
