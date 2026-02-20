import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// TRANSFORMATION TRACKER SCREEN
/// Before/After Photo Comparison for Viral Sharing
/// ═══════════════════════════════════════════════════════════

class TransformationTrackerScreen extends StatefulWidget {
  const TransformationTrackerScreen({super.key});

  @override
  State<TransformationTrackerScreen> createState() =>
      _TransformationTrackerScreenState();
}

class _TransformationTrackerScreenState
    extends State<TransformationTrackerScreen> {
  final List<TransformationEntry> _entries = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load sample entries for demo
    _loadSampleEntries();
  }

  void _loadSampleEntries() {
    // In production, load from database
    _entries.addAll([
      TransformationEntry(
        id: '1',
        date: DateTime.now().subtract(const Duration(days: 90)),
        weight: 85.0,
        bodyFat: 22.0,
        measurements: {'chest': 102, 'waist': 88, 'arms': 35},
        notes: 'Inizio del percorso',
      ),
      TransformationEntry(
        id: '2',
        date: DateTime.now().subtract(const Duration(days: 30)),
        weight: 80.0,
        bodyFat: 18.0,
        measurements: {'chest': 104, 'waist': 82, 'arms': 37},
        notes: 'Dopo 2 mesi di allenamento',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: CleanTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CleanTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trasformazione',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: CleanTheme.primaryColor),
            onPressed: _shareTransformation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Summary
            _buildProgressSummary(),

            const SizedBox(height: 24),

            // Before/After Comparison
            if (_entries.length >= 2) ...[
              _buildBeforeAfterSection(),
              const SizedBox(height: 24),
            ],

            // Timeline
            _buildTimelineSection(),

            const SizedBox(height: 24),

            // Add New Entry Button
            CleanButton(
              text: 'Aggiungi Foto',
              icon: Icons.add_a_photo,
              width: double.infinity,
              onPressed: _addNewEntry,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    if (_entries.length < 2) {
      return _buildEmptyState();
    }

    final first = _entries.first;
    final last = _entries.last;
    final weightDiff = last.weight! - first.weight!;
    final bodyFatDiff = last.bodyFat! - first.bodyFat!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleanTheme.accentGreen.withValues(alpha: 0.1),
            CleanTheme.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CleanTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '🎉 I Tuoi Progressi',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressMetric(
                label: 'Peso',
                value: '${weightDiff.abs().toStringAsFixed(1)} kg',
                isPositive: weightDiff < 0,
                icon: Icons.monitor_weight_outlined,
              ),
              Container(width: 1, height: 50, color: CleanTheme.borderPrimary),
              _buildProgressMetric(
                label: 'Body Fat',
                value: '${bodyFatDiff.abs().toStringAsFixed(1)}%',
                isPositive: bodyFatDiff < 0,
                icon: Icons.percent,
              ),
              Container(width: 1, height: 50, color: CleanTheme.borderPrimary),
              _buildProgressMetric(
                label: 'Giorni',
                value: '${last.date.difference(first.date).inDays}',
                isPositive: true,
                icon: Icons.calendar_today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric({
    required String label,
    required String value,
    required bool isPositive,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isPositive ? CleanTheme.accentGreen : CleanTheme.textSecondary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'Giorni')
              Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPositive
                    ? CleanTheme.accentGreen
                    : CleanTheme.accentRed,
                size: 16,
              ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeAfterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prima & Dopo',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _shareTransformation,
              icon: const Icon(Icons.share, size: 18),
              label: Text(
                'Condividi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Before/After Slider
        _buildComparisonSlider(),
      ],
    );
  }

  Widget _buildComparisonSlider() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Placeholder for before/after images
            Row(
              children: [
                Expanded(
                  child: Container(
                    color: CleanTheme.textSecondary.withValues(alpha: 0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_camera,
                          size: 48,
                          color: CleanTheme.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PRIMA',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _entries.first.date.toString().split(' ')[0],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 2, color: CleanTheme.borderPrimary),
                Expanded(
                  child: Container(
                    color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_camera,
                          size: 48,
                          color: CleanTheme.accentGreen,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'DOPO',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.accentGreen,
                          ),
                        ),
                        Text(
                          _entries.last.date.toString().split(' ')[0],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Watermark
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Powered by GIGI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: CleanTheme.textOnDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._entries.reversed.map((entry) => _buildTimelineEntry(entry)),
      ],
    );
  }

  Widget _buildTimelineEntry(TransformationEntry entry) {
    final isFirst = entry == _entries.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst
                      ? CleanTheme.textSecondary
                      : CleanTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 60, color: CleanTheme.borderPrimary),
            ],
          ),
          const SizedBox(width: 16),
          // Entry card
          Expanded(
            child: CleanCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      if (isFirst)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CleanTheme.textSecondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'INIZIO',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniStat('Peso', '${entry.weight} kg'),
                      const SizedBox(width: 16),
                      _buildMiniStat('BF', '${entry.bodyFat}%'),
                    ],
                  ),
                  if (entry.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: CleanTheme.textTertiary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        children: [
          const Text('📸', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Inizia il tuo percorso',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scatta la tua prima foto per tracciare i progressi',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CleanButton(
            text: 'Scatta Foto',
            icon: Icons.camera_alt,
            onPressed: _addNewEntry,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _addNewEntry() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scegli sorgente',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Fotocamera',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galleria',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          // Show entry form dialog
          _showEntryFormDialog(image.path);
        }
      } catch (e) {
        debugPrint('Error picking image: $e');
      }
    }
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CleanTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderPrimary),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: CleanTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryFormDialog(String imagePath) {
    final weightController = TextEditingController();
    final bodyFatController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: CleanTheme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aggiungi Dettagli',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: bodyFatController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Body Fat (%)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Note (opzionale)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CleanButton(
                text: 'Salva',
                width: double.infinity,
                onPressed: () {
                  final entry = TransformationEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: DateTime.now(),
                    imagePath: imagePath,
                    weight: double.tryParse(weightController.text),
                    bodyFat: double.tryParse(bodyFatController.text),
                    notes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );
                  setState(() => _entries.add(entry));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Foto aggiunta! 📸'),
                      backgroundColor: CleanTheme.accentGreen,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareTransformation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Condivisione in arrivo... 📤'),
        backgroundColor: CleanTheme.primaryColor,
      ),
    );
    // In production: generate comparison image and share
  }
}

/// Model for transformation entries
class TransformationEntry {
  final String id;
  final DateTime date;
  final String? imagePath;
  final double? weight;
  final double? bodyFat;
  final Map<String, double>? measurements;
  final String? notes;

  TransformationEntry({
    required this.id,
    required this.date,
    this.imagePath,
    this.weight,
    this.bodyFat,
    this.measurements,
    this.notes,
  });
}
