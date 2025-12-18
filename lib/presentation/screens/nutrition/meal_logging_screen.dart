import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class MealLoggingScreen extends StatefulWidget {
  const MealLoggingScreen({super.key});

  @override
  State<MealLoggingScreen> createState() => _MealLoggingScreenState();
}

class _MealLoggingScreenState extends State<MealLoggingScreen> {
  late final NutritionService _nutritionService;
  final _formKey = GlobalKey<FormState>();

  String _selectedMealType = 'breakfast';
  final _foodNameController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  // Valori base per 100g (usati per ricalcolo)
  double _baseCaloriesPer100g = 0;
  double _baseProteinPer100g = 0;
  double _baseCarbsPer100g = 0;
  double _baseFatPer100g = 0;

  bool _isSubmitting = false;
  XFile? _imageFile;
  Uint8List? _imageBytes; // For web display
  final ImagePicker _picker = ImagePicker();
  int? _createdMealId;

  final Map<String, String> _mealTypes = {
    'breakfast': 'Colazione',
    'lunch': 'Pranzo',
    'dinner': 'Cena',
    'snack': 'Snack',
    'pre_workout': 'Pre-Workout',
    'post_workout': 'Post-Workout',
  };

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(ApiClient());
    _gramsController.addListener(_recalculateMacros);
  }

  void _recalculateMacros() {
    final grams = double.tryParse(_gramsController.text) ?? 100;
    if (_baseCaloriesPer100g > 0) {
      final multiplier = grams / 100;
      _caloriesController.text = (_baseCaloriesPer100g * multiplier)
          .round()
          .toString();
      _proteinController.text = (_baseProteinPer100g * multiplier)
          .toStringAsFixed(1);
      _carbsController.text = (_baseCarbsPer100g * multiplier).toStringAsFixed(
        1,
      );
      _fatController.text = (_baseFatPer100g * multiplier).toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _gramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Read bytes for web display
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });

        // Chiedi i grammi PRIMA di inviare all'AI
        final grams = await _showGramsInputDialog();
        if (grams == null) return; // Utente ha annullato

        setState(() => _isSubmitting = true);

        final result = await _nutritionService.quickLog(
          imageFile: pickedFile,
          mealType: _selectedMealType,
          grams: grams,
        );

        if (mounted) {
          setState(() => _isSubmitting = false);

          if (result != null && result['success'] == true) {
            final meal = result['meal'];
            final analysis = result['analysis'];

            setState(() {
              _createdMealId = meal['id'];

              if (analysis != null &&
                  analysis['food_items'] != null &&
                  analysis['food_items'].isNotEmpty) {
                final firstItem = analysis['food_items'][0];
                _foodNameController.text =
                    firstItem['food_name'] ?? 'Pasto Rilevato';
              }

              // Salva valori base per 100g (per ricalcolo)
              final calories = (meal['total_calories'] ?? 0).toDouble();
              final protein = (meal['protein_grams'] ?? 0).toDouble();
              final carbs = (meal['carbs_grams'] ?? 0).toDouble();
              final fat = (meal['fat_grams'] ?? 0).toDouble();

              _baseCaloriesPer100g = calories;
              _baseProteinPer100g = protein;
              _baseCarbsPer100g = carbs;
              _baseFatPer100g = fat;

              _gramsController.text = '100';
              _caloriesController.text = calories.round().toString();
              _proteinController.text = protein.toString();
              _carbsController.text = carbs.toString();
              _fatController.text = fat.toString();
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    analysis != null
                        ? 'Pasto analizzato! Verifica i dettagli.'
                        : 'Analisi parziale. Verifica i dati.',
                  ),
                  backgroundColor: analysis != null
                      ? CleanTheme.accentGreen
                      : CleanTheme.accentOrange,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result?['warning'] ??
                        'Analisi fallita. Inserisci manualmente.',
                  ),
                  backgroundColor: CleanTheme.accentOrange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  Future<void> _submitMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final foodItem = {
        'food_name': _foodNameController.text,
        'quantity': 1,
        'unit': 'serving',
        'calories': int.parse(_caloriesController.text),
        'protein_grams': double.parse(_proteinController.text),
        'carbs_grams': double.parse(_carbsController.text),
        'fat_grams': double.parse(_fatController.text),
        'source': _imageFile != null ? 'photo' : 'manual',
      };

      bool success = false;

      if (_createdMealId != null) {
        success = await _nutritionService.updateMeal(
          mealId: _createdMealId!,
          mealType: _selectedMealType,
          totalCalories: int.parse(_caloriesController.text),
          proteinGrams: double.parse(_proteinController.text),
          carbsGrams: double.parse(_carbsController.text),
          fatGrams: double.parse(_fatController.text),
          foodItems: [foodItem],
        );
      } else {
        final meal = await _nutritionService.logMeal(
          mealType: _selectedMealType,
          totalCalories: int.parse(_caloriesController.text),
          proteinGrams: double.parse(_proteinController.text),
          carbsGrams: double.parse(_carbsController.text),
          fatGrams: double.parse(_fatController.text),
          foodItems: [foodItem],
        );
        success = meal != null;
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pasto salvato!'),
              backgroundColor: CleanTheme.accentGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nel salvataggio'),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Scegli Origine Immagine',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: CleanTheme.accentBlue,
                ),
              ),
              title: Text(
                'Fotocamera',
                style: GoogleFonts.inter(color: CleanTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: CleanTheme.accentPurple,
                ),
              ),
              title: Text(
                'Galleria',
                style: GoogleFonts.inter(color: CleanTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showGramsInputDialog() async {
    final controller = TextEditingController(text: '100');
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CleanTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.scale_outlined,
                color: CleanTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Quanti grammi?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Inserisci il peso approssimativo per calcoli macro più precisi',
              style: GoogleFonts.inter(
                color: CleanTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
              decoration: InputDecoration(
                suffixText: 'g',
                suffixStyle: GoogleFonts.inter(
                  fontSize: 20,
                  color: CleanTheme.textSecondary,
                ),
                filled: true,
                fillColor: CleanTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final grams = int.tryParse(controller.text) ?? 100;
              Navigator.pop(context, grams);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Analizza',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Registra Pasto',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMealTypeSelector(),
              const SizedBox(height: 24),

              if (_imageBytes != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _imageBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CleanIconButton(
                        icon: Icons.close,
                        onTap: () => setState(() {
                          _imageFile = null;
                          _imageBytes = null;
                          _createdMealId = null;
                          _foodNameController.clear();
                          _caloriesController.clear();
                          _proteinController.clear();
                          _carbsController.clear();
                          _fatController.clear();
                        }),
                      ),
                    ),
                  ],
                )
              else
                CleanCard(
                  onTap: _showImageSourceDialog,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 36,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scansiona Pasto con AI',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scatta una foto per analisi automatica',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: CleanTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              if (_isSubmitting)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: CleanTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gigi sta analizzando il pasto...',
                        style: GoogleFonts.inter(
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                CleanSectionHeader(title: 'Inserimento Manuale'),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _foodNameController,
                  label: 'Nome Alimento',
                  icon: Icons.restaurant_menu_outlined,
                ),
                const SizedBox(height: 16),

                // Campo Grammi
                _buildTextField(
                  controller: _gramsController,
                  label: 'Quantità (g)',
                  icon: Icons.scale_outlined,
                  keyboardType: TextInputType.number,
                  helperText: 'I macro si ricalcolano automaticamente',
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _caloriesController,
                        label: 'Calorie',
                        icon: Icons.local_fire_department_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _proteinController,
                        label: 'Proteine (g)',
                        icon: Icons.fitness_center_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _carbsController,
                        label: 'Carbo (g)',
                        icon: Icons.grain_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _fatController,
                        label: 'Grassi (g)',
                        icon: Icons.opacity_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                CleanButton(
                  text: _createdMealId != null
                      ? 'Aggiorna Pasto'
                      : 'Salva Pasto',
                  icon: Icons.check,
                  width: double.infinity,
                  onPressed: _isSubmitting ? null : _submitMeal,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _mealTypes.entries.map((entry) {
          final isSelected = _selectedMealType == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMealType = entry.key);
                }
              },
              selectedColor: CleanTheme.primaryColor,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : CleanTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: CleanTheme.surfaceColor,
              side: BorderSide(
                color: isSelected
                    ? CleanTheme.primaryColor
                    : CleanTheme.borderPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        helperText: helperText,
        helperStyle: GoogleFonts.inter(
          color: CleanTheme.textTertiary,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: CleanTheme.textTertiary),
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
          borderSide: const BorderSide(
            color: CleanTheme.primaryColor,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Richiesto';
        }
        return null;
      },
    );
  }
}
