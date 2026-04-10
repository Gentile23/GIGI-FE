import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/health_insights_service.dart';

import 'trend_insight_card.dart';
import 'package:gigi/l10n/app_localizations.dart';

/// ═══════════════════════════════════════════════════════════
/// HEALTH TRENDS CAROUSEL
/// Horizontal scrollable carousel of health insights for dashboard
/// ═══════════════════════════════════════════════════════════
class HealthTrendsCarousel extends StatefulWidget {
  final VoidCallback? onViewAllTap;

  const HealthTrendsCarousel({super.key, this.onViewAllTap});

  @override
  State<HealthTrendsCarousel> createState() => _HealthTrendsCarouselState();
}

class _HealthTrendsCarouselState extends State<HealthTrendsCarousel> {
  final HealthInsightsService _insightsService = HealthInsightsService();
  List<TrendInsight> _insights = [];
  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isInstalling = false;
  bool _healthConnectInstalled = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final isAndroid = _insightsService.isAndroidPlatform;
      final healthConnectInstalled = isAndroid
          ? await _insightsService.isHealthConnectInstalled()
          : true;
      final insights = await _insightsService.getTrendInsights();

      if (mounted) {
        setState(() {
          _insights = insights;
          _healthConnectInstalled = healthConnectInstalled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _installHealthConnect() async {
    setState(() => _isInstalling = true);
    await _insightsService.installHealthConnect();
    final installed = await _insightsService.isHealthConnectInstalled();

    if (!mounted) return;

    setState(() {
      _healthConnectInstalled = installed;
      _isInstalling = false;
    });
  }

  Future<void> _connectHealth() async {
    setState(() => _isConnecting = true);

    final authorized = await _insightsService.connectHealth();

    if (!mounted) return;

    setState(() => _isConnecting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authorized
              ? '${_insightsService.platformName} connesso'
              : 'Permessi Health non concessi',
        ),
        backgroundColor: authorized
            ? CleanTheme.accentGreen
            : CleanTheme.accentOrange,
      ),
    );

    if (authorized) {
      await _loadInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: CleanTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.insightsTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (widget.onViewAllTap != null)
                GestureDetector(
                  onTap: widget.onViewAllTap,
                  child: Text(
                    '${AppLocalizations.of(context)!.viewReport} →',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Insights carousel
        if (_isLoading)
          _buildLoadingState()
        else if (_insights.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _insights.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TrendInsightCard(
                    insight: _insights[index],
                    onTap: widget.onViewAllTap,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.32).clamp(260.0, 340.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: cardHeight,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderSecondary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              size: 48,
              color: CleanTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(
                context,
              )!.connectTo(_insightsService.platformName),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _healthConnectInstalled
                  ? (_insightsService.isAndroidPlatform
                        ? AppLocalizations.of(context)!.syncHealthConnect
                        : AppLocalizations.of(context)!.syncAppleHealth)
                  : AppLocalizations.of(context)!.installHealthConnectInfo,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isConnecting || _isInstalling
                    ? null
                    : (_healthConnectInstalled
                          ? _connectHealth
                          : _installHealthConnect),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CleanTheme.primaryColor,
                  foregroundColor: CleanTheme.textOnDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConnecting || _isInstalling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CleanTheme.textOnDark,
                        ),
                      )
                    : Text(
                        _healthConnectInstalled
                            ? AppLocalizations.of(
                                context,
                              )!.connectTo(_insightsService.platformName)
                            : AppLocalizations.of(
                                context,
                              )!.installHealthConnect,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
