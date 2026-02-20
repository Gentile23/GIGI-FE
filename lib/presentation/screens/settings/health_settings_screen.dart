import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/health_integration_service.dart';
import '../../../core/services/haptic_service.dart';
import 'package:gigi/l10n/app_localizations.dart';

/// ═══════════════════════════════════════════════════════════
/// HEALTH SETTINGS SCREEN
/// Manage Apple Health / Google Health Connect integration
/// ═══════════════════════════════════════════════════════════
class HealthSettingsScreen extends StatefulWidget {
  const HealthSettingsScreen({super.key});

  @override
  State<HealthSettingsScreen> createState() => _HealthSettingsScreenState();
}

class _HealthSettingsScreenState extends State<HealthSettingsScreen> {
  final HealthIntegrationService _healthService = HealthIntegrationService();

  bool _isLoading = true;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _healthConnectInstalled = true;

  // Health data
  int? _stepsToday;
  int? _heartRate;
  double? _sleepHours;
  double? _weight;

  @override
  void initState() {
    super.initState();
    _initializeHealth();
  }

  Future<void> _initializeHealth() async {
    await _healthService.initialize();

    if (Platform.isAndroid) {
      _healthConnectInstalled = await _healthService.isHealthConnectInstalled();
    }

    setState(() {
      _isConnected = _healthService.isAuthorized;
      _isLoading = false;
    });

    if (_isConnected) {
      _loadHealthData();
    }
  }

  Future<void> _loadHealthData() async {
    final steps = await _healthService.getStepsToday();
    final heartRate = await _healthService.getRestingHeartRate();
    final sleep = await _healthService.getSleepHours(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final weight = await _healthService.getCurrentWeight();

    if (mounted) {
      setState(() {
        _stepsToday = steps;
        _heartRate = heartRate;
        _sleepHours = sleep;
        _weight = weight;
      });
    }
  }

  Future<void> _connectHealth() async {
    setState(() => _isConnecting = true);
    HapticService.mediumTap();

    final authorized = await _healthService.requestPermissions();

    if (mounted) {
      setState(() {
        _isConnected = authorized;
        _isConnecting = false;
      });

      if (authorized) {
        HapticService.celebrationPattern();
        _loadHealthData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_healthService.platformName} connesso! ✅'),
            backgroundColor: CleanTheme.accentGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permessi non concessi. Riprova dalle impostazioni del dispositivo.',
            ),
            backgroundColor: CleanTheme.accentOrange,
          ),
        );
      }
    }
  }

  Future<void> _disconnectHealth() async {
    HapticService.lightTap();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disconnettere ${_healthService.platformName}?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'I dati sincronizzati rimarranno, ma non verranno più aggiornati automaticamente.',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.disconnect,
              style: GoogleFonts.inter(color: CleanTheme.accentRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _healthService.disconnect();
      setState(() {
        _isConnected = false;
        _stepsToday = null;
        _heartRate = null;
        _sleepHours = null;
        _weight = null;
      });
    }
  }

  Future<void> _installHealthConnect() async {
    HapticService.mediumTap();
    await _healthService.installHealthConnect();

    // Check again after installation
    await Future.delayed(const Duration(seconds: 2));
    final installed = await _healthService.isHealthConnectInstalled();
    setState(() => _healthConnectInstalled = installed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.healthAndFitness,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform info card
                  _buildPlatformCard(),

                  const SizedBox(height: 24),

                  // Connection status
                  _buildConnectionCard(),

                  if (_isConnected) ...[
                    const SizedBox(height: 24),

                    // Health data preview
                    Text(
                      AppLocalizations.of(context)!.yourData,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHealthDataGrid(),

                    const SizedBox(height: 24),

                    // Auto-sync info
                    _buildAutoSyncInfo(),
                  ],

                  const SizedBox(height: 24),

                  // Data types info
                  _buildDataTypesInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlatformCard() {
    final icon = Platform.isIOS ? '🍎' : '💚';
    final name = _healthService.platformName;
    final description = Platform.isIOS
        ? AppLocalizations.of(context)!.syncAppleHealth
        : AppLocalizations.of(context)!.syncHealthConnect;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Platform.isIOS
              ? [const Color(0xFF000000), const Color(0xFF333333)]
              : [
                  CleanTheme.accentGreen,
                  CleanTheme.accentGreen.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textOnDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    // Health Connect not installed (Android only)
    if (Platform.isAndroid && !_healthConnectInstalled) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CleanTheme.accentOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CleanTheme.accentOrange.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: CleanTheme.accentOrange,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.healthConnectNotInstalled,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.installHealthConnectInfo,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _installHealthConnect,
              icon: const Icon(Icons.download),
              label: Text(AppLocalizations.of(context)!.installHealthConnect),
              style: ElevatedButton.styleFrom(
                backgroundColor: CleanTheme.accentOrange,
                foregroundColor: CleanTheme.textOnDark,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected
              ? CleanTheme.accentGreen
              : CleanTheme.borderSecondary,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? CleanTheme.accentGreen.withValues(alpha: 0.1)
                      : CleanTheme.textTertiary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isConnected ? Icons.check_circle : Icons.link_off,
                  color: _isConnected
                      ? CleanTheme.accentGreen
                      : CleanTheme.textTertiary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnected
                          ? AppLocalizations.of(context)!.connected
                          : AppLocalizations.of(context)!.notConnected,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _isConnected
                            ? CleanTheme.accentGreen
                            : CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _isConnected
                          ? AppLocalizations.of(
                              context,
                            )!.dataSyncedAutomatically
                          : AppLocalizations.of(context)!.connectToSyncWorkouts,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnecting
                  ? null
                  : (_isConnected ? _disconnectHealth : _connectHealth),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConnected
                    ? CleanTheme.accentRed
                    : CleanTheme.primaryColor,
                foregroundColor: CleanTheme.textOnDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CleanTheme.textOnDark,
                      ),
                    )
                  : Text(
                      _isConnected
                          ? AppLocalizations.of(context)!.disconnect
                          : AppLocalizations.of(
                              context,
                            )!.connectTo(_healthService.platformName),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildDataTile(
          '👟',
          AppLocalizations.of(context)!.stepsToday,
          _stepsToday?.toString() ?? '-',
          '',
        ),
        _buildDataTile(
          '❤️',
          AppLocalizations.of(context)!.restingHeartRate,
          _heartRate?.toString() ?? '-',
          'bpm',
        ),
        _buildDataTile(
          '😴',
          AppLocalizations.of(context)!.sleepYesterday,
          _sleepHours?.toStringAsFixed(1) ?? '-',
          AppLocalizations.of(context)!.hours,
        ),
        _buildDataTile(
          '⚖️',
          AppLocalizations.of(context)!.weightLabel,
          _weight?.toStringAsFixed(1) ?? '-',
          'kg',
        ),
      ],
    );
  }

  Widget _buildDataTile(String emoji, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSyncInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, color: CleanTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.autoSyncActive,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.primaryColor,
                  ),
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.workoutsSavedTo(_healthService.platformName),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypesInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.syncedData,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildDataTypeRow(
          AppLocalizations.of(context)!.steps,
          AppLocalizations.of(context)!.trackDailyActivity,
          Icons.directions_walk,
        ),
        _buildDataTypeRow(
          AppLocalizations.of(context)!.heartRateLabel,
          AppLocalizations.of(context)!.heartRateDesc,
          Icons.favorite,
        ),
        _buildDataTypeRow(
          AppLocalizations.of(context)!.sleepLabel,
          AppLocalizations.of(context)!.sleepDesc,
          Icons.bedtime,
        ),
        _buildDataTypeRow(
          AppLocalizations.of(context)!.weightLabel,
          AppLocalizations.of(context)!.trackYourProgress,
          Icons.monitor_weight,
        ),
        _buildDataTypeRow(
          AppLocalizations.of(context)!.workoutsLabel,
          AppLocalizations.of(context)!.syncSessionsAutomatically,
          Icons.fitness_center,
        ),
      ],
    );
  }

  Widget _buildDataTypeRow(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: CleanTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: CleanTheme.accentGreen,
            size: 20,
          ),
        ],
      ),
    );
  }
}
