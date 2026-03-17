import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/quota_service.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../paywall/paywall_screen.dart';
import '../../widgets/gigi/gigi_coach_message.dart';

class MealLoggingScreen extends StatefulWidget {
  final bool isCalculatorMode;

  const MealLoggingScreen({
    super.key,
    this.isCalculatorMode = false,
  });

  @override
  State<MealLoggingScreen> createState() => _MealLoggingScreenState();
}

class _MealLoggingScreenState extends State<MealLoggingScreen> {
  final _fatController = TextEditingController();
  final _customMealNameController = TextEditingController();

  // Services
  late final NutritionService _nutritionService;
  late final QuotaService _quotaService;

  final _formKey = GlobalKey<FormState>();

  String _selectedMealType = 'breakfast';
  final _foodNameController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();

  // Valori base per 100g (usati per ricalcolo)
  double _baseCaloriesPer100g = 0;
  double _baseProteinPer100g = 0;
  double _baseCarbsPer100g = 0;
  double _baseFatPer100g = 0;

  bool _isSubmitting = false;
  bool _hasResult = false;
  bool _isMealTypeConfirmed = false;
  XFile? _imageFile;
  Uint8List? _imageBytes; // For web display
  final ImagePicker _picker = ImagePicker();
  int? _createdMealId;

  Map<String, String> get _mealTypes {
    final l10n = AppLocalizations.of(context)!;
    return {
      'breakfast': l10n.mealBreakfast,
      'lunch': l10n.mealLunch,
      'dinner': l10n.mealDinner,
      'snack': l10n.mealSnack,
      'custom': l10n.mealCustom,
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedMealType = _getSuggestedMealType();
    _nutritionService = NutritionService(ApiClient());
    _quotaService = QuotaService(); 
    _gramsController.addListener(_recalculateMacros);
  }

  String _getSuggestedMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 18) return 'snack';
    if (hour >= 18 && hour < 23) return 'dinner';
    return 'snack'; // Late night snack
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
    _customMealNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final check = await _quotaService.canPerformAction(
      QuotaAction.mealAnalysis,
    );
    if (!check.canPerform) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              check.reason.isNotEmpty
                  ? check.reason
                  : 'Limite scansioni raggiunto. Passa a Premium!',
            ),
            backgroundColor: CleanTheme.accentOrange,
            action: SnackBarAction(
              label: 'UPGRADE',
              textColor: CleanTheme.textOnDark,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaywallScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 60,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
          _hasResult = false;
        });

        final grams = await _showGramsInputDialog();
        if (grams == null) return; 

        await _quotaService.recordUsage(QuotaAction.mealAnalysis);

        setState(() => _isSubmitting = true);

        final finalMealType = _selectedMealType == 'custom' 
            ? _customMealNameController.text.trim().isEmpty 
                ? 'Custom' 
                : _customMealNameController.text.trim()
            : _selectedMealType;

        final result = await _nutritionService.quickLog(
          imageFile: pickedFile,
          mealType: finalMealType,
          grams: grams,
        );

        if (mounted) {
          setState(() => _isSubmitting = false);

          if (result != null && result['success'] == true) {
            final meal = result['meal'];
            final analysis = result['analysis'];

            setState(() {
              _createdMealId = meal['id'];
              _hasResult = true;

              if (analysis != null &&
                  analysis['food_items'] != null &&
                  analysis['food_items'].isNotEmpty) {
                final firstItem = analysis['food_items'][0];
                _foodNameController.text =
                    firstItem['food_name'] ?? 'Pasto Rilevato';
              }

              double parseValue(dynamic value) {
                if (value == null) return 0.0;
                if (value is num) return value.toDouble();
                if (value is String) return double.tryParse(value) ?? 0.0;
                return 0.0;
              }

              final calories = parseValue(meal['total_calories']);
              final protein = parseValue(meal['protein_grams']);
              final carbs = parseValue(meal['carbs_grams']);
              final fat = parseValue(meal['fat_grams']);

              _baseCaloriesPer100g = calories / grams * 100;
              _baseProteinPer100g = protein / grams * 100;
              _baseCarbsPer100g = carbs / grams * 100;
              _baseFatPer100g = fat / grams * 100;

              _gramsController.text = grams.toString();
              _caloriesController.text = calories.round().toString();
              _proteinController.text = protein.toStringAsFixed(1);
              _carbsController.text = carbs.toStringAsFixed(1);
              _fatController.text = fat.toStringAsFixed(1);
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    analysis != null
                        ? 'Pasto analizzato!'
                        : 'Analisi parziale. Verifica i dati.',
                  ),
                  backgroundColor: analysis != null
                      ? CleanTheme.accentGreen
                      : CleanTheme.accentOrange,
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
        ).showSnackBar(const SnackBar(content: Text('Errore durante l\'analisi dell\'immagine')));
      }
    }
  }

  Future<void> _submitMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final foodItem = {
        'food_name': _selectedMealType == 'custom' &&
                _customMealNameController.text.trim().isNotEmpty
            ? _customMealNameController.text.trim()
            : _foodNameController.text,
        'quantity': 1,
        'unit': 'serving',
        'calories': int.parse(_caloriesController.text),
        'protein_grams': double.parse(_proteinController.text),
        'carbs_grams': double.parse(_carbsController.text),
        'fat_grams': double.parse(_fatController.text),
        'source': _imageFile != null ? 'photo' : 'manual',
      };

      final finalMealType = _selectedMealType == 'custom'
          ? _customMealNameController.text.trim().isEmpty
              ? 'Custom'
              : _customMealNameController.text.trim()
          : _selectedMealType;

      bool success = false;

      if (_createdMealId != null) {
        success = await _nutritionService.updateMeal(
          mealId: _createdMealId!,
          mealType: finalMealType,
          totalCalories: int.parse(_caloriesController.text),
          proteinGrams: double.parse(_proteinController.text),
          carbsGrams: double.parse(_carbsController.text),
          fatGrams: double.parse(_fatController.text),
          foodItems: [foodItem],
        );
      } else {
        final meal = await _nutritionService.logMeal(
          mealType: finalMealType,
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
        ).showSnackBar(const SnackBar(content: Text('Errore durante il salvataggio del pasto')));
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
                color: CleanTheme.textOnPrimary,
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
          widget.isCalculatorMode ? 'Calcolatore AI' : 'Registra Pasto',
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
              GigiCoachMessage(
                message: AppLocalizations.of(context)!.gigiMealMessage,
                emotion: GigiEmotion.expert,
              ),
              const SizedBox(height: 24),
              if (!widget.isCalculatorMode) ...[
                _buildMealTypeSelector(),
                const SizedBox(height: 24),
              ],

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
                          _hasResult = false;
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
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [CleanTheme.steelLight, CleanTheme.steelDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 48,
                            color: CleanTheme.textOnDark,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '📸 Scansiona Pasto con AI',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.textOnDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scatta una foto e conta le calorie in 3 secondi!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CleanTheme.textOnDark.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: CleanTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.flash_on,
                                color: CleanTheme.steelLight,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TAP PER SCANSIONARE',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CleanTheme.steelDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(seconds: 8),
                        builder: (context, value, child) {
                          final messages = [
                            '📸 Analizzando il piatto...',
                            '🔍 Identificando ingredienti...',
                            '🧮 Calcolando calorie...',
                            '✨ Quasi fatto...',
                          ];
                          final index = (value * messages.length).floor().clamp(
                            0,
                            messages.length - 1,
                          );
                          return Text(
                            messages[index],
                            style: GoogleFonts.inter(
                              color: CleanTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              else if (!widget.isCalculatorMode || _hasResult) ...[
                CleanSectionHeader(
                  title: AppLocalizations.of(context)!.insertManually,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _foodNameController,
                  label: 'Nome Alimento',
                  icon: Icons.restaurant_menu_outlined,
                  readOnly: widget.isCalculatorMode,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _gramsController,
                  label: 'Quantità (g)',
                  icon: Icons.scale_outlined,
                  keyboardType: TextInputType.number,
                  helperText: 'I macro si ricalcolano automaticamente',
                  readOnly: widget.isCalculatorMode,
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
                        readOnly: widget.isCalculatorMode,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _proteinController,
                        label: 'Proteine (g)',
                        icon: Icons.fitness_center_outlined,
                        keyboardType: TextInputType.number,
                        readOnly: widget.isCalculatorMode,
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
                        readOnly: widget.isCalculatorMode,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _fatController,
                        label: 'Grassi (g)',
                        icon: Icons.opacity_outlined,
                        keyboardType: TextInputType.number,
                        readOnly: widget.isCalculatorMode,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                if (widget.isCalculatorMode) ...[
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.steelDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Chiudi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting ? null : _submitMeal,
                    child: Text(
                      'Salva nel Diario',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _createdMealId != null ? 'Aggiorna Pasto' : 'Salva Pasto',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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
    final l10n = AppLocalizations.of(context)!;
    final suggestedName = _mealTypes[_selectedMealType]!;

    if (!_isMealTypeConfirmed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CleanTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: CleanTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.suggestedMeal,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CleanTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        suggestedName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _isMealTypeConfirmed = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CleanTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.confirmButton,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _isMealTypeConfirmed = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${l10n.change} ✏️',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Se confermato o si vuole cambiare, mostra il selettore completo
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tipo di Pasto',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: CleanTheme.accentGreen,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: _mealTypes.entries.map((entry) {
            final isSelected = _selectedMealType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedMealType = entry.key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? CleanTheme.primaryColor
                              : CleanTheme.borderPrimary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isSelected ? Colors.white : CleanTheme.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.value,
                        style: GoogleFonts.inter(
                          color:
                              isSelected ? Colors.white : CleanTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedMealType == 'custom') ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: _customMealNameController,
            label: 'Nome Pasto Personalizzato',
            icon: Icons.edit_note_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
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
