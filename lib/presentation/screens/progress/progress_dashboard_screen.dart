import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/progress/interactive_body_silhouette.dart';
import '../../../data/services/api_client.dart';
import 'body_measurements_screen.dart';
import 'progress_photos_screen.dart';
import 'progress_comparison_screen.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;

  // Data
  Map<String, dynamic>? _latestMeasurements;
  Map<String, dynamic>? _changes;
  List<dynamic> _measurementsHistory = [];
  List<dynamic> _goals = [];
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch measurements data
      final measurementsResponse = await _apiClient.dio.get(
        '/progress/measurements',
      );
      final historyResponse = await _apiClient.dio.get(
        '/progress/measurements/history',
      );

      // Try to fetch goals (may not exist yet)
      dynamic goalsData;
      try {
        final goalsResponse = await _apiClient.dio.get('/progress/goals');
        goalsData = goalsResponse.data;
      } catch (_) {
        goalsData = null;
      }

      if (mounted) {
        final measurementsData = measurementsResponse.data;
        final historyData = historyResponse.data;

        setState(() {
          _latestMeasurements = measurementsData['latest'];
          _changes = measurementsData['changes'] ?? {};
          _measurementsHistory = historyData['measurements'] ?? [];
          _goals = goalsData?['goals'] ?? [];
          _streak = _calculateStreak();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateStreak() {
    if (_measurementsHistory.isEmpty) return 0;
    // Calculate consecutive weeks with measurements
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < _measurementsHistory.length && i < 52; i++) {
      final measurement = _measurementsHistory[i] as Map<String, dynamic>;
      final dateStr = measurement['measurement_date'] as String?;
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final weeksDiff = now.difference(date).inDays ~/ 7;
          if (weeksDiff <= i + 1) {
            streak++;
          } else {
            break;
          }
        }
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'I Miei Progressi',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BodyMeasurementsScreen()),
            ).then((_) => _loadData()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak & Quick Stats
                    _buildStreakCard(),
                    const SizedBox(height: 20),

                    // Key Changes Summary
                    if (_changes != null && _changes!.isNotEmpty) ...[
                      _buildChangesSection(),
                      const SizedBox(height: 20),
                    ],

                    // Chart Section
                    _buildChartsSection(),
                    const SizedBox(height: 20),

                    // Body Silhouette
                    _buildBodySilhouetteSection(),
                    const SizedBox(height: 20),

                    // Goals Progress
                    _buildGoalsSection(),
                    const SizedBox(height: 20),

                    // Achievements
                    _buildAchievementsSection(),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.primaryColor,
            CleanTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_streak settimane',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'di misurazioni consecutive',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniStat(
                      '📏',
                      '${_measurementsHistory.length}',
                      'misurazioni',
                    ),
                    const SizedBox(width: 24),
                    _buildMiniStat(
                      '📅',
                      _latestMeasurements != null ? 'Oggi' : '-',
                      'ultima',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Circular progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: (_streak / 12).clamp(0, 1),
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                Center(
                  child: Text(
                    '${((_streak / 12) * 100).round()}%',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChangesSection() {
    final changes = _changes ?? {};
    if (changes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📈 Cambiamenti',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProgressComparisonScreen(),
                ),
              ),
              child: const Text('Vedi tutti'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (changes['waist_cm'] != null)
                _buildChangeCard('Vita', changes['waist_cm'] as num, '⭕', true),
              if (changes['bicep_right_cm'] != null)
                _buildChangeCard(
                  'Bicipite',
                  changes['bicep_right_cm'] as num,
                  '💪',
                  false,
                ),
              if (changes['chest_cm'] != null)
                _buildChangeCard(
                  'Petto',
                  changes['chest_cm'] as num,
                  '👕',
                  false,
                ),
              if (changes['weight_kg'] != null)
                _buildChangeCard(
                  'Peso',
                  changes['weight_kg'] as num,
                  '⚖️',
                  true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangeCard(
    String label,
    num change,
    String emoji,
    bool lowerIsBetter,
  ) {
    final isPositive = lowerIsBetter ? change < 0 : change > 0;
    final displayChange = change.abs();
    final color = isPositive ? CleanTheme.accentGreen : CleanTheme.accentRed;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 18,
              ),
              Text(
                displayChange.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Trend Misure',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CleanCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Mini chart for waist
              _buildMiniChart(
                'Circonferenza Vita',
                'waist_cm',
                CleanTheme.primaryColor,
              ),
              const Divider(height: 32),
              _buildMiniChart(
                'Bicipite',
                'bicep_right_cm',
                CleanTheme.accentBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChart(String title, String field, Color color) {
    final values = _measurementsHistory
        .take(10)
        .map((m) => (m as Map<String, dynamic>)[field] as num?)
        .where((v) => v != null)
        .toList()
        .reversed
        .toList();

    if (values.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Aggiungi più misure per vedere il trend',
          style: GoogleFonts.inter(color: CleanTheme.textTertiary),
        ),
      );
    }

    final maxVal = values.reduce((a, b) => a! > b! ? a : b)!;
    final minVal = values.reduce((a, b) => a! < b! ? a : b)!;
    final range = maxVal - minVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            Text(
              '${values.last} cm',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.asMap().entries.map((entry) {
              final value = entry.value!;
              final normalizedHeight = range > 0
                  ? ((value - minVal) / range * 40) + 20
                  : 40.0;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: normalizedHeight,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.3 + (entry.key / values.length * 0.7),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBodySilhouetteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧍 Mappa Corporea',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tocca una zona per vedere i dettagli',
          style: GoogleFonts.inter(
            color: CleanTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        CleanCard(
          padding: const EdgeInsets.all(16),
          child: InteractiveBodySilhouette(
            measurements: _latestMeasurements,
            changes: _changes,
            onBodyPartTap: (partId) {
              debugPrint('Tapped body part: $partId');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🎯 Obiettivi',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddGoalDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_goals.isEmpty)
          _buildEmptyGoalsCard()
        else
          ..._goals.map((goal) => _buildGoalCard(goal as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildEmptyGoalsCard() {
    return CleanCard(
      padding: const EdgeInsets.all(24),
      onTap: _showAddGoalDialog,
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Imposta un obiettivo',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Es. "Vita a 80cm" o "Bicipite a 40cm"',
            style: GoogleFonts.inter(
              color: CleanTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final target = goal['target_value'] as num? ?? 0;
    final current = goal['current_value'] as num? ?? 0;
    final initial = goal['initial_value'] as num? ?? current;
    final progress = (initial - current).abs() / (initial - target).abs();
    final isAchieved = progress >= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved
            ? CleanTheme.accentGreen.withValues(alpha: 0.1)
            : CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAchieved ? CleanTheme.accentGreen : CleanTheme.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal['name'] ?? 'Obiettivo',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              if (isAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🏆 Raggiunto!',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$current',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.primaryColor,
                ),
              ),
              Text(
                ' / $target cm',
                style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: AlwaysStoppedAnimation(
                isAchieved ? CleanTheme.accentGreen : CleanTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    String? selectedMeasurement;
    final targetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CleanTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Nuovo Obiettivo',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Misura',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'waist_cm', child: Text('⭕ Vita')),
                DropdownMenuItem(
                  value: 'bicep_right_cm',
                  child: Text('💪 Bicipite'),
                ),
                DropdownMenuItem(value: 'chest_cm', child: Text('👕 Petto')),
                DropdownMenuItem(value: 'weight_kg', child: Text('⚖️ Peso')),
              ],
              onChanged: (value) => selectedMeasurement = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Obiettivo (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            CleanButton(
              text: 'Salva Obiettivo',
              onPressed: () {
                if (selectedMeasurement != null &&
                    targetController.text.isNotEmpty) {
                  _saveGoal(
                    selectedMeasurement!,
                    double.parse(targetController.text),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGoal(String measurement, double target) async {
    try {
      await _apiClient.dio.post(
        '/progress/goals',
        data: {'measurement_type': measurement, 'target_value': target},
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  Widget _buildAchievementsSection() {
    // Predefined achievements based on progress
    final List<Map<String, dynamic>> achievements = [
      {
        'icon': '📏',
        'title': 'Prima Misura',
        'description': 'Hai registrato la prima misurazione',
        'unlocked': _measurementsHistory.isNotEmpty,
      },
      {
        'icon': '🔥',
        'title': 'Costanza',
        'description': '4 settimane consecutive di misurazioni',
        'unlocked': _streak >= 4,
      },
      {
        'icon': '📉',
        'title': 'Vita Più Snella',
        'description': 'Hai ridotto la vita di 2+ cm',
        'unlocked': (_changes?['waist_cm'] as num? ?? 0) <= -2,
      },
      {
        'icon': '💪',
        'title': 'Braccia Potenti',
        'description': 'Hai aumentato il bicipite di 1+ cm',
        'unlocked': (_changes?['bicep_right_cm'] as num? ?? 0) >= 1,
      },
      {
        'icon': '🏆',
        'title': 'Trasformazione',
        'description': '12 settimane di tracciamento',
        'unlocked': _streak >= 12,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏆 Traguardi',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final unlocked = achievement['unlocked'] as bool;

              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked
                      ? CleanTheme.accentYellow.withValues(alpha: 0.1)
                      : CleanTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked
                        ? CleanTheme.accentYellow
                        : CleanTheme.borderSecondary,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unlocked ? achievement['icon'] : '🔒',
                      style: TextStyle(
                        fontSize: 28,
                        color: unlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement['title'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: unlocked
                            ? CleanTheme.textPrimary
                            : CleanTheme.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Azioni Rapide',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.straighten,
                label: 'Nuova Misura',
                color: CleanTheme.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BodyMeasurementsScreen(),
                  ),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.photo_camera,
                label: 'Foto Progresso',
                color: CleanTheme.accentBlue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressPhotosScreen(),
                  ),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.compare,
                label: 'Confronta',
                color: CleanTheme.accentGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressComparisonScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
