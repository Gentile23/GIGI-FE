import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';

class ManualGoalEntryScreen extends StatefulWidget {
  final int? currentCalories;
  final int? currentProtein;
  final int? currentCarbs;
  final int? currentFat;

  const ManualGoalEntryScreen({
    super.key,
    this.currentCalories,
    this.currentProtein,
    this.currentCarbs,
    this.currentFat,
  });

  @override
  State<ManualGoalEntryScreen> createState() => _ManualGoalEntryScreenState();
}

class _ManualGoalEntryScreenState extends State<ManualGoalEntryScreen> {
  late final NutritionService _nutritionService;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(ApiClient());
    
    _caloriesController = TextEditingController(text: (widget.currentCalories ?? 2000).toString());
    _proteinController = TextEditingController(text: (widget.currentProtein ?? 150).toString());
    _carbsController = TextEditingController(text: (widget.currentCarbs ?? 200).toString());
    _fatController = TextEditingController(text: (widget.currentFat ?? 70).toString());
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _nutritionService.setComprehensiveGoals(
        dailyCalories: int.parse(_caloriesController.text),
        proteinGrams: int.parse(_proteinController.text),
        carbsGrams: int.parse(_carbsController.text),
        fatGrams: int.parse(_fatController.text),
        goalType: 'custom',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Obiettivi personalizzati salvati!'),
              backgroundColor: CleanTheme.accentGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Errore durante il salvataggio');
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

  Future<void> _deleteGoals() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Obiettivi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Sei sicuro di voler eliminare i tuoi obiettivi attuali?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: CleanTheme.accentRed),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await _nutritionService.deleteGoals();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obiettivi eliminati')),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Errore durante l\'eliminazione');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: CleanTheme.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasCurrentGoals = widget.currentCalories != null;
    
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Obiettivi Personalizzati',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Imposta i tuoi macro manualmente',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci i valori target per la tua alimentazione giornaliera.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildInputField(
                controller: _caloriesController,
                label: 'Calorie (kcal)',
                icon: Icons.local_fire_department_rounded,
                color: CleanTheme.primaryColor,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _proteinController,
                      label: 'Proteine (g)',
                      icon: Icons.egg_rounded,
                      color: CleanTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      controller: _carbsController,
                      label: 'Carboidrati (g)',
                      icon: Icons.bakery_dining_rounded,
                      color: CleanTheme.accentOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildInputField(
                controller: _fatController,
                label: 'Grassi (g)',
                icon: Icons.water_drop_rounded,
                color: CleanTheme.accentPurple,
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoals,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: CleanTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Salva Obiettivi',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              if (hasCurrentGoals) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _deleteGoals,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: CleanTheme.accentRed,
                    ),
                    child: const Text(
                      'Elimina Obiettivi Attuali',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color),
            filled: true,
            fillColor: CleanTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CleanTheme.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CleanTheme.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserisci un valore';
            }
            if (int.tryParse(value) == null) {
              return 'Inserisci un numero valido';
            }
            return null;
          },
        ),
      ],
    );
  }
}
