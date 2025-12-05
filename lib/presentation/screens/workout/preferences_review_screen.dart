import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../data/models/user_model.dart';
import '../../screens/profile/edit_preferences_screen.dart';
import '../../../data/models/user_profile_model.dart';
import '../../widgets/clean_widgets.dart';

class PreferencesReviewScreen extends StatelessWidget {
  const PreferencesReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Rivedi Preferenze',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(child: Text('Utente non trovato'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                CleanCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: CleanTheme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rivedi le tue preferenze',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Useremo queste informazioni per generare il tuo piano di allenamento personalizzato. Puoi modificarle se necessario.',
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
                ),
                const SizedBox(height: 24),

                // Personal Info Section
                _buildSectionTitle('Informazioni Personali'),
                _buildPreferenceCard([
                  _buildInfoRow(
                    'Altezza',
                    '${user.height?.toStringAsFixed(0) ?? '-'} cm',
                  ),
                  _buildInfoRow(
                    'Peso',
                    '${user.weight?.toStringAsFixed(0) ?? '-'} kg',
                  ),
                  _buildInfoRow('Genere', _getGenderLabel(user.gender)),
                  _buildInfoRow(
                    'Forma Fisica',
                    user.bodyFatPercentage != null
                        ? _getBodyFatLabel(user.bodyFatPercentage)
                        : _getBodyShapeLabel(user.bodyShape),
                  ),
                ]),
                const SizedBox(height: 16),

                // Training Goals Section
                _buildSectionTitle('Obiettivi di Allenamento'),
                _buildPreferenceCard([
                  _buildInfoRow('Obiettivo', user.goal ?? 'Non specificato'),
                  _buildInfoRow(
                    'Livello',
                    user.experienceLevel ?? 'Non specificato',
                  ),
                  _buildInfoRow(
                    'Frequenza',
                    '${user.weeklyFrequency ?? '-'} giorni/settimana',
                  ),
                ]),
                const SizedBox(height: 16),

                // Training Location Section
                _buildSectionTitle('Luogo di Allenamento'),
                _buildPreferenceCard([
                  _buildInfoRow(
                    'Luogo',
                    user.trainingLocation ?? 'Non specificato',
                  ),
                  _buildInfoRow(
                    'Attrezzatura',
                    user.availableEquipment?.join(', ') ?? 'Nessuna',
                  ),
                ]),
                const SizedBox(height: 16),

                // Training Preferences Section
                _buildSectionTitle('Preferenze di Allenamento'),
                _buildPreferenceCard([
                  _buildInfoRow(
                    'Tipo Allenamento',
                    _getWorkoutTypeLabel(user.workoutType),
                  ),
                  _buildInfoRow(
                    'Split',
                    user.trainingSplit ?? 'Non specificato',
                  ),
                  _buildInfoRow(
                    'Durata Sessione',
                    '${user.sessionDuration ?? '-'} minuti',
                  ),
                  _buildInfoRow(
                    'Cardio',
                    user.cardioPreference ?? 'Non specificato',
                  ),
                  _buildInfoRow(
                    'Mobilità',
                    user.mobilityPreference ?? 'Non specificato',
                  ),
                ]),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CleanButton(
                        text: 'Modifica',
                        isOutlined: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EditPreferencesScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CleanButton(
                        text: 'Genera Piano',
                        onPressed: () => _proceedToGeneration(context, user),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CleanTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildPreferenceCard(List<Widget> children) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderLabel(String? gender) {
    if (gender == null) return 'Non specificato';
    return gender == 'male' ? 'Maschio' : 'Femmina';
  }

  String _getBodyShapeLabel(String? value) {
    if (value == null || value.isEmpty) return 'Non specificato';

    try {
      final normalizedValue = value.toLowerCase().trim();

      final shape = BodyShape.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == normalizedValue,
        orElse: () {
          throw Exception('No match');
        },
      );

      switch (shape) {
        case BodyShape.skinny:
          return 'Molto Magro';
        case BodyShape.lean:
          return 'Magro';
        case BodyShape.athletic:
          return 'Atletico';
        case BodyShape.muscular:
          return 'Muscoloso';
        case BodyShape.overweight:
          return 'Sovrappeso';
        case BodyShape.average:
          return 'Nella Media';
      }
    } catch (e) {
      return value[0].toUpperCase() + value.substring(1);
    }
  }

  String _getBodyFatLabel(BodyFatPercentage? value) {
    if (value == null) return 'Non specificato';

    switch (value) {
      case BodyFatPercentage.veryHigh:
        return 'Molto Alta (>25%)';
      case BodyFatPercentage.high:
        return 'Alta (20-25%)';
      case BodyFatPercentage.average:
        return 'Media (15-20%)';
      case BodyFatPercentage.athletic:
        return 'Atletica (10-15%)';
      case BodyFatPercentage.veryLean:
        return 'Molto Definita (<10%)';
    }
  }

  String _getWorkoutTypeLabel(String? value) {
    if (value == null || value.isEmpty) return 'Non specificato';

    try {
      final normalizedValue = value.toLowerCase().trim();

      final type = WorkoutType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == normalizedValue,
        orElse: () {
          throw Exception('No match');
        },
      );

      switch (type) {
        case WorkoutType.hypertrophy:
          return 'Ipertrofia';
        case WorkoutType.strength:
          return 'Forza';
        case WorkoutType.endurance:
          return 'Resistenza';
        case WorkoutType.functional:
          return 'Funzionale';
        case WorkoutType.calisthenics:
          return 'Calisthenics';
      }
    } catch (e) {
      return value[0].toUpperCase() + value.substring(1);
    }
  }

  Future<void> _proceedToGeneration(
    BuildContext context,
    UserModel user,
  ) async {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      ),
    );

    try {
      final success = await workoutProvider.generatePlan();

      if (context.mounted) {
        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Generazione avviata! L\'AI sta creando il tuo piano.',
              ),
              backgroundColor: CleanTheme.accentBlue,
            ),
          );

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/main', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                workoutProvider.error ??
                    'Errore durante la generazione del piano',
              ),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

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
