import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/clean_theme.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - 32,
          ),
          decoration: BoxDecoration(
            color: CleanTheme.primaryColor,
            borderRadius: BorderRadius.circular(100),
            boxShadow: CleanTheme.floatingShadow,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = currentIndex == index;

                return GestureDetector(
                  onTap: () {
                    if (!isActive) {
                      HapticFeedback.lightImpact();
                      onTap(index);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, // Tighter horizontal padding
                      vertical: 6, // Slimmer vertical profile
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(
                            6,
                          ), // Smaller icon circle
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.8),
                            size: 20, // Slightly smaller icon
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
