import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../../data/services/api_client.dart';

class ProgressComparisonScreen extends StatefulWidget {
  const ProgressComparisonScreen({super.key});

  @override
  State<ProgressComparisonScreen> createState() =>
      _ProgressComparisonScreenState();
}

class _ProgressComparisonScreenState extends State<ProgressComparisonScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;

  // Data
  Map<String, dynamic>? _comparisonData;
  List<dynamic> _measurementsHistory = [];

  // Photo comparison slider
  double _sliderValue = 0.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final comparisonResponse = await _apiClient.dio.get('/progress/compare');
      final historyResponse = await _apiClient.dio.get(
        '/progress/measurements/history',
      );

      if (mounted) {
        setState(() {
          _comparisonData = comparisonResponse.data;
          _measurementsHistory = historyResponse.data['measurements'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'I Tuoi Progressi',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CleanTheme.primaryColor,
          labelColor: CleanTheme.primaryColor,
          unselectedLabelColor: CleanTheme.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '📸 Foto', icon: Icon(Icons.photo_library)),
            Tab(text: '📊 Misure', icon: Icon(Icons.show_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildPhotosTab(), _buildMeasurementsTab()],
            ),
    );
  }

  Widget _buildPhotosTab() {
    // Safely handle photos data - could be Map, List, or null
    final photosData = _comparisonData?['photos'];
    Map<String, dynamic> photos = {};

    if (photosData is Map<String, dynamic>) {
      photos = photosData;
    }
    // If it's a List or other type, treat as empty

    if (photos.isEmpty) {
      return _buildEmptyState(
        emoji: '📸',
        title: AppLocalizations.of(context)!.noPhotosYetTitle,
        subtitle: AppLocalizations.of(context)!.noPhotosYetDesc,
        action: 'Aggiungi Foto',
        onAction: () => Navigator.pushNamed(context, '/progress/photos'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '🔥 La Tua Trasformazione',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scorri per confrontare prima e dopo',
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Photo comparison for each type
          ...['front', 'side_left', 'back'].map((type) {
            final comparison = photos[type];
            if (comparison == null) return const SizedBox.shrink();
            return _buildPhotoComparison(
              type: type,
              initialUrl: comparison['initial'],
              latestUrl: comparison['latest'],
              daysApart: comparison['days_apart'] ?? 0,
            );
          }),

          const SizedBox(height: 32),

          // Add more photos button
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/progress/photos'),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Aggiungi Nuove Foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CleanTheme.primaryColor,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: CleanTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoComparison({
    required String type,
    required String initialUrl,
    required String latestUrl,
    required int daysApart,
  }) {
    final typeLabels = {
      'front': AppLocalizations.of(context)!.frontPhoto,
      'side_left': AppLocalizations.of(context)!.sidePhoto,
      'back': AppLocalizations.of(context)!.backPhoto,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                typeLabels[type] ?? type,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$daysApart giorni',
                  style: GoogleFonts.inter(
                    color: CleanTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Comparison slider
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 0.75,
              child: Stack(
                children: [
                  // Latest photo (full)
                  Positioned.fill(
                    child: Image.network(
                      latestUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: CleanTheme.surfaceColor,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),

                  // Initial photo (clipped based on slider)
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _PhotoClipper(_sliderValue),
                      child: Image.network(
                        initialUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: CleanTheme.surfaceColor,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),

                  // Divider line
                  Positioned(
                    left: MediaQuery.of(context).size.width * _sliderValue - 50,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Labels
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _buildPhotoLabel('PRIMA', CleanTheme.accentRed),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _buildPhotoLabel('DOPO', CleanTheme.accentGreen),
                  ),
                ],
              ),
            ),
          ),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: CleanTheme.primaryColor,
              inactiveTrackColor: CleanTheme.borderSecondary,
              thumbColor: Colors.white,
              overlayColor: CleanTheme.primaryColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _sliderValue,
              onChanged: (value) => setState(() => _sliderValue = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    final measurements =
        _comparisonData?['measurements'] as Map<String, dynamic>? ?? {};
    final changes = measurements['changes'] as Map<String, dynamic>? ?? {};
    final initial = measurements['initial'] as Map<String, dynamic>?;
    final latest = measurements['latest'] as Map<String, dynamic>?;

    if (initial == null) {
      return _buildEmptyState(
        emoji: '📏',
        title: AppLocalizations.of(context)!.noMeasurementsYetTitle,
        subtitle: AppLocalizations.of(context)!.noMeasurementsYetDesc,
        action: 'Aggiungi Misure',
        onAction: () => Navigator.pushNamed(context, '/progress/measurements'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          if (changes.isNotEmpty) ...[
            Text(
              '📈 Cambiamenti',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildChangesGrid(changes),
            const SizedBox(height: 32),
          ],

          // Comparison table
          Text(
            '📊 Confronto Misure',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonTable(initial, latest, changes),

          const SizedBox(height: 32),

          // History chart placeholder
          Text(
            '📉 Storico',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryChart(),

          const SizedBox(height: 32),

          // Update measurements button
          CleanButton(
            text: 'Aggiorna Misure',
            onPressed: () =>
                Navigator.pushNamed(context, '/progress/measurements'),
            icon: Icons.edit,
          ),
        ],
      ),
    );
  }

  Widget _buildChangesGrid(Map<String, dynamic> changes) {
    final labels = {
      'bicep_right_cm': ('Bicipite DX', '💪'),
      'bicep_left_cm': ('Bicipite SX', '💪'),
      'chest_cm': ('Petto', '👕'),
      'waist_cm': ('Vita', '⭕'),
      'hips_cm': ('Fianchi', '🍑'),
      'weight_kg': ('Peso', '⚖️'),
    };

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: changes.entries.map((entry) {
        final label = labels[entry.key];
        if (label == null) return const SizedBox.shrink();

        final rawValue = entry.value;
        final value = rawValue is num
            ? rawValue
            : (num.tryParse(rawValue?.toString() ?? '0') ?? 0);
        final isPositive = value > 0;
        final isGoodChange = _isGoodChange(entry.key, value);

        return Container(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isGoodChange
                ? CleanTheme.accentGreen.withValues(alpha: 0.1)
                : CleanTheme.accentRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isGoodChange
                  ? CleanTheme.accentGreen.withValues(alpha: 0.3)
                  : CleanTheme.accentRed.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label.$2, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    label.$1,
                    style: GoogleFonts.inter(
                      color: CleanTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isGoodChange
                        ? CleanTheme.accentGreen
                        : CleanTheme.accentRed,
                    size: 20,
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${value.toStringAsFixed(1)} cm',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isGoodChange
                          ? CleanTheme.accentGreen
                          : CleanTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isGoodChange(String field, num value) {
    // For biceps/chest - increase is good
    if (field.contains('bicep') || field == 'chest_cm') {
      return value > 0;
    }
    // For waist - decrease is good
    if (field == 'waist_cm') {
      return value < 0;
    }
    // Default: increase is good (muscle gain focus)
    return value > 0;
  }

  Widget _buildComparisonTable(
    Map<String, dynamic> initial,
    Map<String, dynamic>? latest,
    Map<String, dynamic> changes,
  ) {
    final measurements = [
      ('Bicipite DX', 'bicep_right_cm', '💪'),
      ('Bicipite SX', 'bicep_left_cm', '💪'),
      ('Petto', 'chest_cm', '👕'),
      ('Vita', 'waist_cm', '⭕'),
      ('Fianchi', 'hips_cm', '🍑'),
      ('Coscia DX', 'thigh_right_cm', '🦵'),
      ('Peso', 'weight_kg', '⚖️'),
    ];

    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                child: Text(
                  'Inizio',
                  style: GoogleFonts.inter(
                    color: CleanTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Oggi',
                  style: GoogleFonts.inter(
                    color: CleanTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Δ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(),

          ...measurements.map((m) {
            final initialValue = initial[m.$2];
            final latestValue = latest?[m.$2];
            final changeRaw = changes[m.$2];
            final change = changeRaw is num
                ? changeRaw
                : (num.tryParse(changeRaw?.toString() ?? ''));

            if (initialValue == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(m.$3, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          m.$1,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      initialValue?.toString() ?? '-',
                      style: GoogleFonts.outfit(
                        color: CleanTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      latestValue?.toString() ?? '-',
                      style: GoogleFonts.outfit(
                        color: CleanTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: change != null
                        ? Text(
                            '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                            style: GoogleFonts.outfit(
                              color: _isGoodChange(m.$2, change)
                                  ? CleanTheme.accentGreen
                                  : CleanTheme.accentRed,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const Text('-', textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryChart() {
    if (_measurementsHistory.isEmpty) {
      return CleanCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Aggiungi più misure per vedere lo storico',
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
        ),
      );
    }

    // Simple bar chart representation
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ultimi ${_measurementsHistory.length} rilevamenti',
            style: GoogleFonts.inter(
              color: CleanTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _measurementsHistory
                  .take(10)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                    final measurement = entry.value as Map<String, dynamic>;
                    final waistValue = measurement['waist_cm'];
                    final waist = waistValue is num
                        ? waistValue
                        : (num.tryParse(waistValue?.toString() ?? '0') ?? 0);
                    // Normalize to 0-100 range (assuming waist between 60-120cm)
                    final height = ((waist - 60) / 60 * 100).clamp(10, 100);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: height.toDouble(),
                              decoration: BoxDecoration(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.3 + (entry.key / 10 * 0.7),
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Circonferenza vita nel tempo',
              style: GoogleFonts.inter(
                color: CleanTheme.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String emoji,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CleanButton(text: action, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

// Custom clipper for before/after photo comparison
class _PhotoClipper extends CustomClipper<Rect> {
  final double percentage;

  _PhotoClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * percentage, size.height);
  }

  @override
  bool shouldReclip(covariant _PhotoClipper oldClipper) {
    return oldClipper.percentage != percentage;
  }
}
