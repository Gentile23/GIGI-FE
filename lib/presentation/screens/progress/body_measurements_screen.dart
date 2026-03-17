import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../../data/services/api_client.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../widgets/gigi/gigi_coach_message.dart';
import '../../../core/services/haptic_service.dart';

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
  bool _isLoading = false;
  bool _showTips = false;
  Map<String, dynamic>? _latestMeasurements;
  final Map<String, String?> _validationErrors = {};

  final Map<String, (double, double)> _validRanges = {
    'bicep_right_cm': (15.0, 70.0),
    'bicep_left_cm': (15.0, 70.0),
    'chest_cm': (50.0, 180.0),
    'waist_cm': (40.0, 180.0),
    'hips_cm': (50.0, 200.0),
    'thigh_right_cm': (20.0, 110.0),
    'thigh_left_cm': (20.0, 110.0),
    'calf_cm': (15.0, 70.0),
  };

  @override
  void initState() {
    super.initState();
    _fetchLatestMeasurements();
  }

  Future<void> _fetchLatestMeasurements() async {
    try {
      final response = await _apiClient.get('progress/measurements');
      if (response['latest'] != null) {
        setState(() {
          _latestMeasurements = response['latest'] is Map<String, dynamic> 
              ? response['latest'] 
              : null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching latest measurements: $e');
    }
  }

  final _bicepRightController = TextEditingController();
  final _bicepLeftController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _thighRightController = TextEditingController();
  final _thighLeftController = TextEditingController();
  final _calfController = TextEditingController();

  @override
  void dispose() {
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: widget.isOnboarding 
        ? null 
        : AppBar(
            title: Text(
              l10n.bodyMeasurements,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            backgroundColor: CleanTheme.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEZIONE 1: GIGI COACH HEADER
              _buildCoachHeader(l10n),
              const SizedBox(height: 24),

              // SEZIONE 2: TIPS (Collapsible)
              _buildTipsSection(l10n),
              const SizedBox(height: 24),

              // SEZIONE 3: INPUT GROUPS
              _buildModernGroupHeader(l10n.arms, Icons.fitness_center),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernInputCard(
                      label: l10n.bicepRight,
                      controller: _bicepRightController,
                      apiKey: 'bicep_right_cm',
                      icon: Icons.rotate_right,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernInputCard(
                      label: l10n.bicepLeft,
                      controller: _bicepLeftController,
                      apiKey: 'bicep_left_cm',
                      icon: Icons.rotate_left,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildModernGroupHeader(l10n.torso, Icons.accessibility),
              const SizedBox(height: 12),
              _buildModernInputCard(
                label: l10n.chest,
                controller: _chestController,
                apiKey: 'chest_cm',
                icon: Icons.straighten,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernInputCard(
                      label: l10n.waist,
                      controller: _waistController,
                      apiKey: 'waist_cm',
                      icon: Icons.circle_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernInputCard(
                      label: l10n.hips,
                      controller: _hipsController,
                      apiKey: 'hips_cm',
                      icon: Icons.wc,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildModernGroupHeader(l10n.legs, Icons.directions_walk),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernInputCard(
                      label: l10n.thighRight,
                      controller: _thighRightController,
                      apiKey: 'thigh_right_cm',
                      icon: Icons.airline_stops,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernInputCard(
                      label: l10n.thighLeft,
                      controller: _thighLeftController,
                      apiKey: 'thigh_left_cm',
                      icon: Icons.airline_stops,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildModernInputCard(
                label: l10n.calf,
                controller: _calfController,
                apiKey: 'calf_cm',
                icon: Icons.run_circle_outlined,
              ),
              const SizedBox(height: 32),

              // SEZIONE 4: ACTION BUTTON
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: CleanButton(
                  text: _isLoading ? l10n.saving : l10n.saveAndContinue,
                  onPressed: _isLoading ? null : _saveMeasurements,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernGroupHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: CleanTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: CleanTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInputCard({
    required String label,
    required TextEditingController controller,
    required String apiKey,
    IconData? icon,
    bool isRequired = false,
  }) {
    final previousValue = _latestMeasurements?[apiKey];

    return CleanCard(
      padding: const EdgeInsets.all(12),
      enableGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: CleanTheme.textPrimary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ),
              if (isRequired)
                const Text(' *',
                    style: TextStyle(color: CleanTheme.accentRed)),
            ],
          ),
          const SizedBox(height: 8),
          if (previousValue != null)
            Text(
              'PREC: $previousValue cm',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: CleanTheme.accentBlue,
              ),
            )
          else
            Text(
              'No dati',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: CleanTheme.textTertiary,
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CleanTheme.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CleanTheme.borderSecondary),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CleanTheme.primaryColor,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.0',
                      hintStyle: TextStyle(color: CleanTheme.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    onChanged: (value) {
                      final val = double.tryParse(value);
                      final range = _validRanges[apiKey];
                      setState(() {
                        if (val != null && range != null) {
                          if (val < range.$1 || val > range.$2) {
                                _validationErrors[apiKey] = 'Valore insolito?';
                          } else {
                            _validationErrors[apiKey] = null;
                          }
                        } else {
                          _validationErrors[apiKey] = null;
                        }
                      });
                    },
                  ),
                ),
                Text(
                  'cm',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_validationErrors[apiKey] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _validationErrors[apiKey]!,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.accentGold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoachHeader(AppLocalizations l10n) {
    return Column(
      children: [
        LiquidSteelContainer(
          borderRadius: 20,
          enableShine: true,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitora i tuoi progressi',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CleanTheme.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inserisci le tue misure per vedere come cambia il tuo fisico.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textOnPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.straighten,
                  size: 44,
                  color: CleanTheme.textOnPrimary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const GigiCoachMessage(
          message: 'Le misure sono fondamentali per capire la tua trasformazione, specialmente quando la bilancia non si muove!',
          emotion: GigiEmotion.expert,
        ),
      ],
    );
  }

  Widget _buildTipsSection(AppLocalizations l10n) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticService.lightTap();
            setState(() => _showTips = !_showTips);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CleanTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CleanTheme.borderSecondary),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: CleanTheme.accentGold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.howToTakeMeasurements,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _showTips ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: CleanTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_showTips) ...[
          const SizedBox(height: 8),
          CleanCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: CleanTheme.primaryLight.withValues(alpha: 0.5),
            child: Column(
              children: [
                _buildTipRow(Icons.access_time, l10n.measureSameTime, l10n.morningsFasting),
                _buildTipRow(Icons.square_foot, l10n.flexibleTape, l10n.noRigidRulers),
                _buildTipRow(Icons.refresh, l10n.repeatTwice, l10n.ensureCorrect),
                _buildTipRow(Icons.air, l10n.relaxNoContracting, l10n.naturalPosition),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CleanTheme.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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


  Future<void> _saveMeasurements() async {
    HapticService.mediumTap();
    setState(() => _isLoading = true);

    double? parseValue(String text, String apiKey) {
      if (text.isNotEmpty) return double.tryParse(text);
      // Se il campo è vuoto, usa l'ultimo valore salvato (se esiste) per evitare lo 0
      final prev = _latestMeasurements?[apiKey];
      if (prev != null) return double.tryParse(prev.toString());
      return null;
    }

    try {
      final data = {
        'measurement_date': DateTime.now().toIso8601String().split('T')[0],
        'bicep_right_cm': parseValue(_bicepRightController.text, 'bicep_right_cm'),
        'bicep_left_cm': parseValue(_bicepLeftController.text, 'bicep_left_cm'),
        'chest_cm': parseValue(_chestController.text, 'chest_cm'),
        'waist_cm': parseValue(_waistController.text, 'waist_cm'),
        'hips_cm': parseValue(_hipsController.text, 'hips_cm'),
        'thigh_right_cm': parseValue(_thighRightController.text, 'thigh_right_cm'),
        'thigh_left_cm': parseValue(_thighLeftController.text, 'thigh_left_cm'),
        'calf_cm': parseValue(_calfController.text, 'calf_cm'),
      };

      // Rimuovi chiavi con valore null
      data.removeWhere((key, value) => value == null);

      await _apiClient.dio.post('/progress/measurements', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ${AppLocalizations.of(context)!.measurementsSummary}',
            ),
            backgroundColor: CleanTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        
        String errorMessage = 'Ops! Qualcosa è andato storto durante il salvataggio.';
        
        if (e is DioException) {
          if (e.response?.statusCode == 422) {
            final errors = e.response?.data['errors'] as Map<String, dynamic>?;
            if (errors != null && errors.isNotEmpty) {
              // Prendi il primo errore e rendilo leggibile
              String field = errors.keys.first;
              String rawMessage = errors.values.first[0].toString();
              
              // Traduzione dei nomi dei campi per l'utente
              final fieldTranslations = {
                'bicep_right_cm': 'Bicipite destro',
                'bicep_left_cm': 'Bicipite sinistro',
                'chest_cm': 'Petto',
                'waist_cm': 'Vita',
                'hips_cm': 'Fianchi',
                'thigh_right_cm': 'Coscia destra',
                'thigh_left_cm': 'Coscia sinistra',
                'calf_cm': 'Polpaccio',
                'measurement_date': 'Data misurazione',
              };

              String cleanField = fieldTranslations[field] ?? field;
              
              if (rawMessage.contains('greater than')) {
                errorMessage = 'Il valore per $cleanField è troppo alto. Controlla di aver inserito i dati corretti.';
              } else if (rawMessage.contains('less than')) {
                errorMessage = 'Il valore per $cleanField è troppo basso.';
              } else {
                errorMessage = 'Dati non validi per $cleanField. Riprova.';
              }
            } else {
              errorMessage = 'I dati inseriti non sono validi. Controlla i valori e riprova.';
            }
          } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Problema di connessione. Verifica la tua rete e riprova.';
          } else if (e.response?.statusCode == 401) {
            errorMessage = 'Sessione scaduta. Per favore, effettua di nuovo l\'accesso.';
          } else {
            errorMessage = 'Impossibile raggiungere il server al momento. Riprova più tardi.';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: CleanTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
