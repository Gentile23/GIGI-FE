import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/biometric_model.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/modern_theme.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _recoveryScore!.readinessColor.withOpacity(0.3),
              _recoveryScore!.readinessColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _recoveryScore!.readinessColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _recoveryScore!.readinessColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
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
                    'Recovery Score',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$scorePercentage% - ${_recoveryScore!.readinessLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _recoveryScore!.readinessColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
          ],
        ),
      ),
    );
  }
}
