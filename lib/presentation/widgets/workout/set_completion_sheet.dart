import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

/// ═══════════════════════════════════════════════════════════
/// SET COMPLETION SHEET - Quick logging after completing a set
/// Psychology: Instant feedback reinforces behavior, reduces friction
/// ═══════════════════════════════════════════════════════════
class SetCompletionSheet extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final double? previousWeight;
  final int? previousReps;
  final Function(int reps, double? weight) onComplete;
  final VoidCallback? onCancel;

  const SetCompletionSheet({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.onComplete,
    this.previousWeight,
    this.previousReps,
    this.onCancel,
  });

  @override
  State<SetCompletionSheet> createState() => _SetCompletionSheetState();

  /// Show the sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required int setNumber,
    required int targetReps,
    required Function(int reps, double? weight) onComplete,
    double? previousWeight,
    int? previousReps,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetCompletionSheet(
        setNumber: setNumber,
        targetReps: targetReps,
        onComplete: onComplete,
        previousWeight: previousWeight,
        previousReps: previousReps,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

class _SetCompletionSheetState extends State<SetCompletionSheet>
    with SingleTickerProviderStateMixin {
  late int _reps;
  late double _weight;
  late AnimationController _successController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _reps = widget.targetReps;
    _weight = widget.previousWeight ?? 0;

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  void _incrementReps() {
    HapticService.lightTap();
    setState(() => _reps++);
  }

  void _decrementReps() {
    if (_reps > 1) {
      HapticService.lightTap();
      setState(() => _reps--);
    }
  }

  void _incrementWeight() {
    HapticService.lightTap();
    setState(() => _weight += 2.5);
  }

  void _decrementWeight() {
    if (_weight >= 2.5) {
      HapticService.lightTap();
      setState(() => _weight -= 2.5);
    }
  }

  void _complete() async {
    HapticService.celebrationPattern();

    setState(() => _showSuccess = true);
    await _successController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    widget.onComplete(_reps, _weight > 0 ? _weight : null);
    if (mounted && widget.onCancel != null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: CleanTheme.accentGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serie ${widget.setNumber} Completata!',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Registra il tuo risultato',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Reps counter
              _buildCounter(
                label: 'RIPETIZIONI',
                value: _reps.toString(),
                previousValue: widget.previousReps != null
                    ? 'Precedente: ${widget.previousReps}'
                    : null,
                onDecrement: _decrementReps,
                onIncrement: _incrementReps,
                color: CleanTheme.primaryColor,
              ),

              const SizedBox(height: 20),

              // Weight counter
              _buildCounter(
                label: 'PESO (KG)',
                value: _weight > 0 ? _weight.toStringAsFixed(1) : '-',
                previousValue: widget.previousWeight != null
                    ? 'Precedente: ${widget.previousWeight!.toStringAsFixed(1)} kg'
                    : null,
                onDecrement: _decrementWeight,
                onIncrement: _incrementWeight,
                color: CleanTheme.accentOrange,
              ),

              const SizedBox(height: 32),

              // Complete button
              GestureDetector(
                onTap: _showSuccess ? null : _complete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _showSuccess
                          ? [CleanTheme.accentGreen, CleanTheme.accentGreen]
                          : [CleanTheme.primaryColor, const Color(0xFF2A2A5A)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_showSuccess
                                    ? CleanTheme.accentGreen
                                    : CleanTheme.primaryColor)
                                .withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showSuccess ? Icons.check : Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _showSuccess ? 'SALVATO!' : 'CONFERMA',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color color,
    String? previousValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (previousValue != null)
                Text(
                  previousValue,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircleButton(
                icon: Icons.remove,
                onTap: onDecrement,
                color: color,
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 80,
                child: Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 32),
              _buildCircleButton(
                icon: Icons.add,
                onTap: onIncrement,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
