import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../../data/services/api_client.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const BodyMeasurementsScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final _apiClient = ApiClient();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers for measurements
  final _bicepRightController = TextEditingController();
  final _bicepLeftController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _thighRightController = TextEditingController();
  final _thighLeftController = TextEditingController();
  final _calfController = TextEditingController();

  final List<_MeasurementGuide> _guides = [
    _MeasurementGuide(
      title: '📏 Come prendere le misure',
      subtitle: 'Segui questi consigli per misure accurate',
      tips: [
        (
          '⏰',
          'Misura sempre alla stessa ora',
          'Preferibilmente al mattino, a digiuno',
        ),
        ('📐', 'Usa un metro da sarto flessibile', 'Non usare righelli rigidi'),
        (
          '🔄',
          'Ripeti ogni misura 2 volte',
          'Per assicurarti che sia corretta',
        ),
        (
          '💨',
          'Rilassati, non contrarre',
          'Posizione naturale, respiro normale',
        ),
      ],
    ),
    _MeasurementGuide(
      title: '💪 Braccia',
      subtitle: 'Misura i tuoi bicipiti',
      tips: [
        ('📍', 'Posizione', 'Braccio flesso a 90°, pugno chiuso'),
        ('📐', 'Dove misurare', 'Nel punto più spesso del muscolo'),
        ('🔄', 'Ripeti per entrambi', 'Potrebbero essere leggermente diversi'),
      ],
    ),
    _MeasurementGuide(
      title: '🫁 Torso',
      subtitle: 'Petto, vita e fianchi',
      tips: [
        ('👕', 'Petto', 'Metro sotto le ascelle, sul punto più sporgente'),
        ('⭕', 'Vita', 'All\'altezza dell\'ombelico, posizione naturale'),
        ('🍑', 'Fianchi', 'Nel punto più largo dei glutei'),
      ],
    ),
    _MeasurementGuide(
      title: '🦵 Gambe',
      subtitle: 'Cosce e polpacci',
      tips: [
        ('📍', 'Coscia', 'A metà tra inguine e ginocchio, gamba rilassata'),
        ('🦶', 'Polpaccio', 'Nel punto più largo, in piedi'),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _bicepRightController.dispose();
    _bicepLeftController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _thighRightController.dispose();
    _thighLeftController.dispose();
    _calfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: Text(
                'Misure Corporee',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              backgroundColor: CleanTheme.surfaceColor,
              iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildIntroPage(),
                  _buildArmsPage(),
                  _buildTorsoPage(),
                  _buildLegsPage(),
                  _buildSummaryPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              height: isCurrent ? 6 : 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? CleanTheme.primaryColor
                    : CleanTheme.borderSecondary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIntroPage() {
    final guide = _guides[0];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('📏', style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Il Tuo Punto di Partenza',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Queste misure ci aiutano a creare la scheda perfetta per te e a tracciare i tuoi progressi nel tempo.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Tips card
          CleanCard(
            backgroundColor: CleanTheme.primaryLight,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ...guide.tips.map(
                  (tip) => _buildTipRow(tip.$1, tip.$2, tip.$3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          CleanButton(
            text: 'Inizia le Misure',
            onPressed: _nextPage,
            icon: Icons.arrow_forward,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _skipMeasurements,
              child: Text(
                'Salta per ora',
                style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArmsPage() {
    final guide = _guides[1];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guide.subtitle,
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Instruction card
          _buildInstructionCard(guide.tips),

          const SizedBox(height: 24),

          // Inputs
          _buildMeasurementInput(
            controller: _bicepRightController,
            label: 'Bicipite Destro',
            emoji: '💪',
            hint: 'es. 35',
          ),
          const SizedBox(height: 16),
          _buildMeasurementInput(
            controller: _bicepLeftController,
            label: 'Bicipite Sinistro',
            emoji: '💪',
            hint: 'es. 34.5',
          ),

          const SizedBox(height: 32),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildTorsoPage() {
    final guide = _guides[2];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guide.subtitle,
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildInstructionCard(guide.tips),

          const SizedBox(height: 24),

          _buildMeasurementInput(
            controller: _chestController,
            label: 'Petto',
            emoji: '👕',
            hint: 'es. 100',
          ),
          const SizedBox(height: 16),
          _buildMeasurementInput(
            controller: _waistController,
            label: 'Vita',
            emoji: '⭕',
            hint: 'es. 80',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildMeasurementInput(
            controller: _hipsController,
            label: 'Fianchi',
            emoji: '🍑',
            hint: 'es. 95',
          ),

          const SizedBox(height: 32),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildLegsPage() {
    final guide = _guides[3];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guide.subtitle,
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildInstructionCard(guide.tips),

          const SizedBox(height: 24),

          _buildMeasurementInput(
            controller: _thighRightController,
            label: 'Coscia Destra',
            emoji: '🦵',
            hint: 'es. 55',
          ),
          const SizedBox(height: 16),
          _buildMeasurementInput(
            controller: _thighLeftController,
            label: 'Coscia Sinistra',
            emoji: '🦵',
            hint: 'es. 54.5',
          ),
          const SizedBox(height: 16),
          _buildMeasurementInput(
            controller: _calfController,
            label: 'Polpaccio',
            emoji: '🦶',
            hint: 'es. 38',
          ),

          const SizedBox(height: 32),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('✅', style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Riepilogo Misure',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Ecco le tue misure di partenza',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 32),

          // Summary cards
          _buildSummaryCard('💪 Braccia', [
            ('Bicipite DX', _bicepRightController.text),
            ('Bicipite SX', _bicepLeftController.text),
          ]),
          const SizedBox(height: 16),
          _buildSummaryCard('🫁 Torso', [
            ('Petto', _chestController.text),
            ('Vita', _waistController.text),
            ('Fianchi', _hipsController.text),
          ]),
          const SizedBox(height: 16),
          _buildSummaryCard('🦵 Gambe', [
            ('Coscia DX', _thighRightController.text),
            ('Coscia SX', _thighLeftController.text),
            ('Polpaccio', _calfController.text),
          ]),

          const SizedBox(height: 32),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CleanTheme.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: CleanTheme.accentBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Potrai aggiornare le misure ogni settimana per vedere i progressi!',
                    style: GoogleFonts.inter(
                      color: CleanTheme.accentBlue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          CleanButton(
            text: _isLoading ? 'Salvataggio...' : 'Salva e Continua',
            onPressed: _isLoading ? null : _saveMeasurements,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _goToStep(_currentStep - 1),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: CleanTheme.borderPrimary),
            ),
            child: Text(
              'Modifica',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(List<(String, String, String)> tips) {
    return CleanCard(
      backgroundColor: CleanTheme.surfaceColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: CleanTheme.accentYellow,
              ),
              const SizedBox(width: 8),
              Text(
                'Come misurare',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          color: CleanTheme.textPrimary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '${tip.$2}: ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: tip.$3,
                            style: TextStyle(color: CleanTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementInput({
    required TextEditingController controller,
    required String label,
    required String emoji,
    required String hint,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    if (isRequired)
                      Text(' *', style: TextStyle(color: CleanTheme.accentRed)),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.primaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.outfit(
                      color: CleanTheme.textTertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'cm',
            style: GoogleFonts.inter(
              color: CleanTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _goToStep(_currentStep - 1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: CleanTheme.borderPrimary),
            ),
            child: Text(
              'Indietro',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: CleanButton(text: 'Continua', onPressed: _nextPage),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<(String, String)> measurements) {
    final validMeasurements = measurements
        .where((m) => m.$2.isNotEmpty)
        .toList();
    if (validMeasurements.isEmpty) return const SizedBox.shrink();

    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...validMeasurements.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    m.$1,
                    style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                  ),
                  Text(
                    '${m.$2} cm',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step <= 4) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipMeasurements() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveMeasurements() async {
    setState(() => _isLoading = true);

    try {
      final data = {
        'measurement_date': DateTime.now().toIso8601String().split('T')[0],
        if (_bicepRightController.text.isNotEmpty)
          'bicep_right_cm': double.parse(_bicepRightController.text),
        if (_bicepLeftController.text.isNotEmpty)
          'bicep_left_cm': double.parse(_bicepLeftController.text),
        if (_chestController.text.isNotEmpty)
          'chest_cm': double.parse(_chestController.text),
        if (_waistController.text.isNotEmpty)
          'waist_cm': double.parse(_waistController.text),
        if (_hipsController.text.isNotEmpty)
          'hips_cm': double.parse(_hipsController.text),
        if (_thighRightController.text.isNotEmpty)
          'thigh_right_cm': double.parse(_thighRightController.text),
        if (_thighLeftController.text.isNotEmpty)
          'thigh_left_cm': double.parse(_thighLeftController.text),
        if (_calfController.text.isNotEmpty)
          'calf_cm': double.parse(_calfController.text),
      };

      await _apiClient.dio.post('/progress/measurements', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Misure salvate con successo!'),
            backgroundColor: CleanTheme.accentGreen,
          ),
        );

        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }
}

class _MeasurementGuide {
  final String title;
  final String subtitle;
  final List<(String, String, String)> tips;

  const _MeasurementGuide({
    required this.title,
    required this.subtitle,
    required this.tips,
  });
}
