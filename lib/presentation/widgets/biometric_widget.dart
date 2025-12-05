import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/biometric_model.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/clean_theme.dart';
import '../screens/biometric/biometric_dashboard_screen.dart';

class BiometricWidget extends StatefulWidget {
  const BiometricWidget({super.key});

  @override
  State<BiometricWidget> createState() => _BiometricWidgetState();
}

class _BiometricWidgetState extends State<BiometricWidget> {
  late final BiometricService _biometricService;
  EnhancedRecoveryScore? _recoveryScore;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    final insights = await _biometricService.getInsights();
    if (mounted && insights != null) {
      setState(() {
        _recoveryScore = insights['recovery_score'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _recoveryScore == null) {
      return const SizedBox.shrink();
    }

    final scorePercentage = (_recoveryScore!.score * 100).toInt();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BiometricDashboardScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _recoveryScore!.readinessColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _recoveryScore!.readinessColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _recoveryScore!.readinessColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: _recoveryScore!.readinessColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Punteggio Recupero',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$scorePercentage% - ${_recoveryScore!.readinessLabel}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _recoveryScore!.readinessColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: CleanTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
