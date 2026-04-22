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
  static const double _horizontalPadding = 24;
  static const double _defaultInsightCardWidth = 280;
  static const double _maxFocusedCardWidth = 420;

  final HealthInsightsService _insightsService = HealthInsightsService();
  List<TrendInsight> _insights = [];
  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isInstalling = false;
  bool _healthConnectInstalled = true;
  bool _isConnected = false;

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
      final isConnected = await _insightsService.initialize();
      final insights = await _insightsService.getTrendInsights();

      if (mounted) {
        setState(() {
          _insights = insights.isEmpty ? [] : [insights.first];
          _healthConnectInstalled = healthConnectInstalled;
          _isConnected = isConnected;
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
      setState(() => _isLoading = true);
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
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
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

        // Single focused insight
        if (_isLoading)
          _buildLoadingState()
        else if (_insights.isEmpty)
          _buildEmptyState()
        else
          _buildFocusCard(),
      ],
    );
  }

  Widget _buildFocusCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (_horizontalPadding * 2);
        var focusedWidth = availableWidth > 0
            ? availableWidth
            : _defaultInsightCardWidth;
        if (focusedWidth > _maxFocusedCardWidth) {
          focusedWidth = _maxFocusedCardWidth;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Center(
            child: TrendInsightCard(
              insight: _insights.first,
              onTap: widget.onViewAllTap,
              width: focusedWidth,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Container(
        width: double.infinity,
        height: 180,
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
  }

  Widget _buildEmptyState() {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.32).clamp(260.0, 340.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Container(
        constraints: BoxConstraints(minHeight: cardHeight),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected
                    ? Icons.sync_problem_rounded
                    : Icons.health_and_safety_outlined,
                size: 48,
                color: CleanTheme.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                _isConnected
                    ? 'Nessun dato trovato'
                    : AppLocalizations.of(
                        context,
                      )!.connectTo(_insightsService.platformName),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _isConnected
                    ? 'Abbiamo i permessi ma non troviamo dati per oggi. Assicurati che i dati siano presenti in ${_insightsService.platformName}.'
                    : (_healthConnectInstalled
                          ? (_insightsService.isAndroidPlatform
                                ? AppLocalizations.of(context)!.syncHealthConnect
                                : AppLocalizations.of(context)!.syncAppleHealth)
                          : AppLocalizations.of(
                              context,
                            )!.installHealthConnectInfo),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: double.infinity,
                ),
                child: ElevatedButton(
                  onPressed: _isConnecting || _isInstalling
                      ? null
                      : (_isConnected
                            ? _loadInsights
                            : (_healthConnectInstalled
                                  ? _connectHealth
                                  : _installHealthConnect)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CleanTheme.primaryColor,
                    foregroundColor: CleanTheme.textOnDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
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
                          _isConnected
                              ? 'Riprova sincronizzazione'
                              : (_healthConnectInstalled
                                    ? AppLocalizations.of(
                                        context,
                                      )!.connectTo(_insightsService.platformName)
                                    : AppLocalizations.of(
                                        context,
                                      )!.installHealthConnect),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
