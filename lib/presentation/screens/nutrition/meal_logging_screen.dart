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
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

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
  }

  @override
  void dispose() {
    _foodNameController.dispose();
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
          _isSubmitting = true;
        });

        final result = await _nutritionService.quickLog(
          imageFile: pickedFile,
          mealType: _selectedMealType,
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

              _caloriesController.text = (meal['total_calories'] ?? 0)
                  .toString();
              _proteinController.text = (meal['protein_grams'] ?? 0).toString();
              _carbsController.text = (meal['carbs_grams'] ?? 0).toString();
              _fatController.text = (meal['fat_grams'] ?? 0).toString();
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
                        'Analisi pasto in corso...',
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
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
