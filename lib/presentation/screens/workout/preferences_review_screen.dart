import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../data/models/user_model.dart';
import '../../screens/profile/edit_preferences_screen.dart';
import '../../../data/models/user_profile_model.dart';

class PreferencesReviewScreen extends StatelessWidget {
  const PreferencesReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rivedi Preferenze')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(child: Text('Utente non trovato'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Card(
                  color: AppColors.primaryNeon.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryNeon,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rivedi le tue preferenze',
                                style: AppTextStyles.h5.copyWith(
                                  color: AppColors.primaryNeon,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Useremo queste informazioni per generare il tuo piano di allenamento personalizzato. Puoi modificarle se necessario.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EditPreferencesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifica'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _proceedToGeneration(context, user),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Genera Piano'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppColors.primaryNeon,
                        ),
                      ),
                    ),
                  ],
                ),
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
        style: AppTextStyles.h5.copyWith(color: AppColors.primaryNeon),
      ),
    );
  }

  Widget _buildPreferenceCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
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

    // Debug: print the actual value received
    print('DEBUG: bodyShape value = "$value"');

    try {
      // Try to match with enum values (case-insensitive)
      final normalizedValue = value.toLowerCase().trim();

      final shape = BodyShape.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == normalizedValue,
        orElse: () {
          print('DEBUG: No matching BodyShape enum for "$value"');
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
      print('DEBUG: Error converting bodyShape: $e');
      // Return a capitalized version of the raw value as fallback
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
      // Try to match with enum values (case-insensitive)
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
      // Return a capitalized version of the raw value as fallback
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await workoutProvider.generatePlan();

      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Generazione avviata! L\'AI sta creando il tuo piano.',
              ),
              backgroundColor: Colors.blue,
            ),
          );

          // Navigate to home screen
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/main', (route) => false);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                workoutProvider.error ??
                    'Errore durante la generazione del piano',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
