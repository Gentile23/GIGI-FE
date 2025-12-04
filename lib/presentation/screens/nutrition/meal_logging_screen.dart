import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';

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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  int? _createdMealId;

  final Map<String, String> _mealTypes = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
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
        setState(() {
          _imageFile = File(pickedFile.path);
          _isSubmitting = true;
        });

        // Call quickLog immediately to analyze
        final result = await _nutritionService.quickLog(
          imagePath: pickedFile.path,
          mealType: _selectedMealType,
        );

        if (mounted) {
          setState(() => _isSubmitting = false);

          if (result != null && result['success'] == true) {
            final meal = result['meal'];
            final analysis = result['analysis'];

            setState(() {
              _createdMealId = meal['id'];

              // Populate fields from analysis
              if (analysis != null &&
                  analysis['food_items'] != null &&
                  analysis['food_items'].isNotEmpty) {
                final firstItem = analysis['food_items'][0];
                _foodNameController.text =
                    firstItem['food_name'] ?? 'Detected Meal';
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
                        ? '✅ Meal analyzed! Verify details below.'
                        : '⚠️ Analysis partially succeeded. Please verify.',
                  ),
                  backgroundColor: analysis != null
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result?['warning'] ??
                        'Analysis failed. Please enter details manually.',
                  ),
                  backgroundColor: Colors.orange,
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
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

      // If we already created a meal via quickLog, update it
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
        // Normal logMeal
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
              content: Text('✅ Meal logged successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to save meal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModernTheme.cardColor,
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
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
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Log Meal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ModernTheme.cardColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMealTypeSelector(),
              const SizedBox(height: 24),

              // Photo Upload/Display
              if (_imageFile != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() {
                          _imageFile = null;
                          _createdMealId = null;
                          _foodNameController.clear();
                          _caloriesController.clear();
                          _proteinController.clear();
                          _carbsController.clear();
                          _fatController.clear();
                        }),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                )
              else
                ModernCard(
                  onTap: _showImageSourceDialog,
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: ModernTheme.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan Meal with AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ModernTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Take a photo for automatic nutrition analysis',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              if (_isSubmitting)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing meal...'),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Manual Entry',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _foodNameController,
                  label: 'Food Name',
                  icon: Icons.restaurant_menu,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _caloriesController,
                        label: 'Calories',
                        icon: Icons.local_fire_department,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _proteinController,
                        label: 'Protein (g)',
                        icon: Icons.fitness_center,
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
                        label: 'Carbs (g)',
                        icon: Icons.grain,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _fatController,
                        label: 'Fat (g)',
                        icon: Icons.opacity,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                ModernButton(
                  text: _createdMealId != null ? 'Update Meal' : 'Save Meal',
                  onPressed: _isSubmitting ? null : _submitMeal,
                ),
              ],
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
              selectedColor: ModernTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: ModernTheme.cardColor,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white60),
        filled: true,
        fillColor: ModernTheme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ModernTheme.primaryColor),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }
}
