import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

/// ═══════════════════════════════════════════════════════════
/// FAB BOTTOM NAV BAR - 4 tabs with central FAB
/// Psychology: Reduces cognitive load (4 items vs 6)
/// FAB creates strong visual affordance for primary action
/// ═══════════════════════════════════════════════════════════
class FABBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFABPressed;
  final List<FABNavItem> items;
  final String fabLabel;

  const FABBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFABPressed,
    required this.items,
    this.fabLabel = 'START',
  });

  @override
  Widget build(BuildContext context) {
    // Split items: 2 before FAB, 2 after FAB
    final leftItems = items.take(2).toList();
    final rightItems = items.skip(2).toList();

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Navigation Items Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left items
                  ...leftItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildNavItem(item, index, currentIndex == index);
                  }),

                  // Spacer for FAB
                  const SizedBox(width: 80),

                  // Right items
                  ...rightItems.asMap().entries.map((entry) {
                    final index = entry.key + 2; // Offset by 2
                    final item = entry.value;
                    return _buildNavItem(item, index, currentIndex == index);
                  }),
                ],
              ),
            ),

            // Central FAB
            Positioned(top: -28, child: _buildFAB()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(FABNavItem item, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 12 : 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 24,
                color: isSelected
                    ? CleanTheme.primaryColor
                    : CleanTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? CleanTheme.primaryColor
                    : CleanTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        onFABPressed();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CleanTheme.accentGreen,
              CleanTheme.accentGreen.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CleanTheme.accentGreen.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            Text(
              fabLabel,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FABNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FABNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// ═══════════════════════════════════════════════════════════
/// PULSATING FAB - Animated FAB that draws attention
/// Psychology: Movement attracts attention (Gestalt principle)
/// ═══════════════════════════════════════════════════════════
class PulsatingFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? color;

  const PulsatingFAB({
    super.key,
    required this.onPressed,
    this.label = 'START',
    this.icon = Icons.play_arrow_rounded,
    this.color,
  });

  @override
  State<PulsatingFAB> createState() => _PulsatingFABState();
}

class _PulsatingFABState extends State<PulsatingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? CleanTheme.accentGreen;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: () {
              HapticService.mediumTap();
              widget.onPressed();
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 32),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
