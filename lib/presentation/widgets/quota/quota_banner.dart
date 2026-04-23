import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/clean_theme.dart';
import '../../../data/services/quota_service.dart';
import '../../../providers/quota_provider.dart';
import '../../screens/paywall/paywall_screen.dart';

class QuotaBanner extends StatefulWidget {
  final QuotaAction action;
  final String? title;
  final String? subtitle;
  final bool compact;
  final bool showUpgradeButton;
  final VoidCallback? onUpgrade;

  const QuotaBanner({
    super.key,
    required this.action,
    this.title,
    this.subtitle,
    this.compact = false,
    this.showUpgradeButton = true,
    this.onUpgrade,
  });

  @override
  State<QuotaBanner> createState() => _QuotaBannerState();
}

class _QuotaBannerState extends State<QuotaBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quotaProvider = context.read<QuotaProvider>();
      if (!quotaProvider.hasStatus && !quotaProvider.isLoading) {
        quotaProvider.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuotaProvider>(
      builder: (context, quotaProvider, _) {
        if (quotaProvider.isLoading && !quotaProvider.hasStatus) {
          return _QuotaBannerShell(
            compact: widget.compact,
            child: const _QuotaLoadingContent(),
          );
        }

        if (quotaProvider.error != null && !quotaProvider.hasStatus) {
          return _QuotaBannerShell(
            compact: widget.compact,
            tone: _QuotaTone.warning,
            child: _QuotaErrorContent(
              message: 'Limiti non disponibili',
              onRetry: () => quotaProvider.refresh(),
            ),
          );
        }

        final viewData = _QuotaViewData.fromProvider(
          quotaProvider,
          widget.action,
          title: widget.title,
          subtitle: widget.subtitle,
        );

        if (viewData == null) {
          return const SizedBox.shrink();
        }

        return _QuotaBannerShell(
          compact: widget.compact,
          tone: viewData.tone,
          child: _QuotaContent(
            data: viewData,
            compact: widget.compact,
            showUpgradeButton: widget.showUpgradeButton && !viewData.canUse,
            onUpgrade: widget.onUpgrade ?? () => _openPaywall(context),
          ),
        );
      },
    );
  }

  void _openPaywall(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
  }
}

class _QuotaBannerShell extends StatelessWidget {
  final Widget child;
  final bool compact;
  final _QuotaTone tone;

  const _QuotaBannerShell({
    required this.child,
    this.compact = false,
    this.tone = _QuotaTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone.color;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _QuotaContent extends StatelessWidget {
  final _QuotaViewData data;
  final bool compact;
  final bool showUpgradeButton;
  final VoidCallback onUpgrade;

  const _QuotaContent({
    required this.data,
    required this.compact,
    required this.showUpgradeButton,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final color = data.tone.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 32 : 36,
              height: compact ? 32 : 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data.icon, color: color, size: compact ? 18 : 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data.valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        if (!data.isUnlimited && data.progress != null) ...[
          SizedBox(height: compact ? 10 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 5,
              backgroundColor: CleanTheme.chromeSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
        if (showUpgradeButton) ...[
          SizedBox(height: compact ? 10 : 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text('Sblocca più utilizzi'),
              style: TextButton.styleFrom(
                foregroundColor: CleanTheme.textOnPrimary,
                backgroundColor: CleanTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuotaLoadingContent extends StatelessWidget {
  const _QuotaLoadingContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Aggiornamento limiti',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuotaErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _QuotaErrorContent({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: CleanTheme.accentOrange,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Riprova')),
      ],
    );
  }
}

class _QuotaViewData {
  final String title;
  final String subtitle;
  final String valueText;
  final bool canUse;
  final bool isUnlimited;
  final double? progress;
  final IconData icon;
  final _QuotaTone tone;

  const _QuotaViewData({
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.canUse,
    required this.isUnlimited,
    required this.progress,
    required this.icon,
    required this.tone,
  });

  static _QuotaViewData? fromProvider(
    QuotaProvider provider,
    QuotaAction action, {
    String? title,
    String? subtitle,
  }) {
    if (action == QuotaAction.workoutPlan) {
      final quota = provider.workoutPlanUsage;
      if (quota == null) return null;

      final isUnlimited = quota.isUnlimited;
      final canUse = quota.canUse;

      return _QuotaViewData(
        title: title ?? _fallbackTitle(action),
        subtitle:
            subtitle ??
            (isUnlimited
                ? 'Piano workout illimitato'
                : canUse
                ? 'Disponibile ${quota.periodLabel}'
                : 'Nuovo piano tra ${quota.daysUntilNext} giorni'),
        valueText: isUnlimited ? '∞' : quota.periodLabel,
        canUse: canUse,
        isUnlimited: isUnlimited,
        progress: null,
        icon: _iconFor(action),
        tone: _toneFor(canUse: canUse, isUnlimited: isUnlimited),
      );
    }

    final usage = provider.usageFor(action);
    if (usage == null) return null;

    final progress = usage.isUnlimited || usage.limit <= 0
        ? null
        : (usage.used / usage.limit).clamp(0.0, 1.0);
    final period = usage.periodLabel.isNotEmpty
        ? usage.periodLabel
        : _fallbackPeriodLabel(usage.period);

    return _QuotaViewData(
      title:
          title ??
          (usage.label.isNotEmpty ? usage.label : _fallbackTitle(action)),
      subtitle:
          subtitle ??
          (usage.isUnlimited
              ? 'Utilizzi illimitati'
              : '${usage.used}/${usage.limit} usati $period'),
      valueText: usage.isUnlimited ? '∞' : '${usage.remaining}/${usage.limit}',
      canUse: usage.canUse,
      isUnlimited: usage.isUnlimited,
      progress: progress,
      icon: _iconFor(action),
      tone: _toneFor(canUse: usage.canUse, isUnlimited: usage.isUnlimited),
    );
  }

  static String _fallbackTitle(QuotaAction action) {
    return switch (action) {
      QuotaAction.formAnalysis => 'Form Check AI',
      QuotaAction.mealAnalysis => 'Snap & Track AI',
      QuotaAction.recipes => 'Chef AI',
      QuotaAction.customWorkout => 'Workout custom',
      QuotaAction.workoutPlan => 'Piano workout',
      QuotaAction.executeWithGigi => 'Esegui con GIGI',
      QuotaAction.shoppingList => 'Lista spesa',
      QuotaAction.changeMeal => 'Cambio Menu',
      QuotaAction.changeFood => 'Smart Swap',
      QuotaAction.foodDuel => 'Food Duel AI',
      QuotaAction.pdfDiet => 'Analisi PDF Dieta',
      QuotaAction.workoutChat => 'Chat AI',
      QuotaAction.exerciseAlternatives => 'Alternative esercizio',
      QuotaAction.similarExercises => 'Esercizi simili',
    };
  }

  static String _fallbackPeriodLabel(String period) {
    return switch (period) {
      'day' => 'al giorno',
      'week' => 'a settimana',
      'month' => 'al mese',
      'lifetime' => 'una tantum',
      'unlimited' => 'illimitato',
      _ => 'per periodo',
    };
  }

  static IconData _iconFor(QuotaAction action) {
    return switch (action) {
      QuotaAction.formAnalysis => Icons.videocam_rounded,
      QuotaAction.mealAnalysis => Icons.camera_alt_rounded,
      QuotaAction.recipes => Icons.restaurant_menu_rounded,
      QuotaAction.customWorkout => Icons.fitness_center_rounded,
      QuotaAction.workoutPlan => Icons.calendar_month_rounded,
      QuotaAction.executeWithGigi => Icons.play_circle_rounded,
      QuotaAction.shoppingList => Icons.shopping_bag_rounded,
      QuotaAction.changeMeal => Icons.swap_horiz_rounded,
      QuotaAction.changeFood => Icons.compare_arrows_rounded,
      QuotaAction.foodDuel => Icons.balance_rounded,
      QuotaAction.pdfDiet => Icons.picture_as_pdf_rounded,
      QuotaAction.workoutChat => Icons.chat_bubble_rounded,
      QuotaAction.exerciseAlternatives => Icons.alt_route_rounded,
      QuotaAction.similarExercises => Icons.hub_rounded,
    };
  }

  static _QuotaTone _toneFor({
    required bool canUse,
    required bool isUnlimited,
  }) {
    if (isUnlimited) return _QuotaTone.success;
    if (!canUse) return _QuotaTone.blocked;
    return _QuotaTone.neutral;
  }
}

enum _QuotaTone {
  neutral(CleanTheme.accentBlue),
  success(CleanTheme.accentGreen),
  warning(CleanTheme.accentOrange),
  blocked(CleanTheme.accentRed);

  final Color color;
  const _QuotaTone(this.color);
}
