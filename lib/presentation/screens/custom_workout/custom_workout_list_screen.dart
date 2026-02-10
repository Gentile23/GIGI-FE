import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/services/custom_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../widgets/clean_widgets.dart';
import 'create_custom_workout_screen.dart';
import 'workout_pdf_upload_screen.dart';

/// Screen showing the list of user's custom workout plans
class CustomWorkoutListScreen extends StatefulWidget {
  const CustomWorkoutListScreen({super.key});

  @override
  State<CustomWorkoutListScreen> createState() =>
      _CustomWorkoutListScreenState();
}

class _CustomWorkoutListScreenState extends State<CustomWorkoutListScreen> {
  late CustomWorkoutService _customWorkoutService;
  List<CustomWorkoutPlan> _plans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customWorkoutService = CustomWorkoutService(ApiClient());
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _customWorkoutService.getCustomWorkouts();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _plans = result['plans'] as List<CustomWorkoutPlan>;
        } else {
          _error = result['message'] as String?;
        }
      });
    }
  }

  Future<void> _deleteWorkout(CustomWorkoutPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.cardColor,
        title: Text(
          AppLocalizations.of(context)!.deleteWorkoutTitle,
          style: GoogleFonts.outfit(
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sei sicuro di voler eliminare "${plan.name}"?',
          style: GoogleFonts.outfit(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.outfit(color: CleanTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _customWorkoutService.deleteCustomWorkout(plan.id);
      if (result['success'] == true) {
        _loadWorkouts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scheda eliminata con successo'),
              backgroundColor: CleanTheme.accentGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Errore nell\'eliminazione'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myWorkoutsTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          IconButton(
            onPressed: () async {
              // Navigate to PDF Upload
              // We need to import WorkoutPdfUploadScreen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutPdfUploadScreen(),
                ),
              );
              if (result == true) {
                _loadWorkouts();
              }
            },
            icon: const Icon(Icons.upload_file),
            tooltip: 'Carica PDF',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCustomWorkoutScreen(),
            ),
          );
          if (result == true) {
            _loadWorkouts();
          }
        },
        backgroundColor: CleanTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: Text(
          'Nuova Scheda',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: CleanTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWorkouts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CleanTheme.primaryColor,
                ),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    if (_plans.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadWorkouts,
      color: CleanTheme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildWorkoutCard(_plans[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: CleanTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessuna Scheda Personalizzata',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crea la tua prima scheda di allenamento\npersonalizzata selezionando gli esercizi\nche preferisci dal nostro database.',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: CleanTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CleanButton(
              text: 'Crea Prima Scheda',
              icon: Icons.add,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCustomWorkoutScreen(),
                  ),
                );
                if (result == true) {
                  _loadWorkouts();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(CustomWorkoutPlan plan) {
    return GestureDetector(
      onTap: () async {
        // Navigate to edit screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateCustomWorkoutScreen(existingPlan: plan),
          ),
        );
        if (result == true) {
          _loadWorkouts();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: plan.isActive
                ? CleanTheme.primaryColor.withValues(alpha: 0.3)
                : Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: CleanTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      if (plan.description != null &&
                          plan.description!.isNotEmpty)
                        Text(
                          plan.description!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: CleanTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteWorkout(plan),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              children: [
                _buildStatChip(
                  Icons.format_list_numbered,
                  '${plan.exerciseCount} esercizi',
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.timer_outlined,
                  '~${plan.estimatedDuration} min',
                ),
              ],
            ),
            // Exercise preview
            if (plan.exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: plan.exercises.take(3).map((we) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      we.exercise.name,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (plan.exercises.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+${plan.exercises.length - 3} altri esercizi',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CleanTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
