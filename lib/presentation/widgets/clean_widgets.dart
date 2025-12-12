import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:GIGI/core/theme/clean_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════
/// CLEAN BUTTON - Rounded & Modern
/// ═══════════════════════════════════════════════════════════
class CleanButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutlined;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CleanButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isOutlined = false,
    this.icon,
    this.trailingIcon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ??
        (isPrimary ? CleanTheme.textPrimary : CleanTheme.surfaceColor);
    final fgColor =
        textColor ??
        (isPrimary ? CleanTheme.surfaceColor : CleanTheme.textPrimary);

    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: CleanTheme.textPrimary,
            side: const BorderSide(color: CleanTheme.borderPrimary, width: 1.5),
            padding:
                padding ??
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _buildContent(CleanTheme.textPrimary),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          padding:
              padding ??
              const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _buildContent(fgColor),
      ),
    );
  }

  Widget _buildContent(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 20, color: color),
        ],
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN CARD - KINETIC GLASS IMPLEMENTATION
/// ═══════════════════════════════════════════════════════════
class CleanCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool hasShadow;
  final bool hasBorder;
  final double borderRadius;
  final bool isSelected;
  final bool enableGlass;

  const CleanCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.hasShadow = true,
    this.hasBorder = true,
    this.borderRadius = 24, // Increased default radius for Gigi ID
    this.isSelected = false,
    this.enableGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    // Kinetic Gradient - Subtle shine
    final kineticGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.02),
      ],
      stops: const [0.0, 1.0],
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: hasShadow ? CleanTheme.cardShadow : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // Glassmorphism Blur Layer
                if (enableGlass)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ), // Heavy blur for premium glass
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                // Background & Kinetic Overlay
                Container(
                  padding: padding ?? const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        backgroundColor ??
                        (isSelected
                            ? CleanTheme.primaryColor.withValues(alpha: 0.05)
                            : CleanTheme.surfaceColor.withOpacity(
                                0.85,
                              )), // Semi-transparent for glass
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: hasBorder
                        ? Border.all(
                            color: isSelected
                                ? CleanTheme.primaryColor
                                : (borderColor ??
                                      Colors.white.withValues(
                                        alpha: 0.6,
                                      )), // Glassy border
                            width: isSelected
                                ? 2
                                : 1, // Thicker selected border
                          )
                        : null,
                    gradient: enableGlass && !isSelected
                        ? kineticGradient
                        : null,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN IMAGE CARD - Card with hero image on top
/// ═══════════════════════════════════════════════════════════
class CleanImageCard extends StatelessWidget {
  final String? imageUrl;
  final Widget? imageWidget;
  final String title;
  final String? subtitle;
  final String? badge;
  final double? rating;
  final String? ratingCount;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double height;
  final double borderRadius;

  const CleanImageCard({
    super.key,
    this.imageUrl,
    this.imageWidget,
    required this.title,
    this.subtitle,
    this.badge,
    this.rating,
    this.ratingCount,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.height = 200,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: CleanTheme.imageCardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Image
              SizedBox(
                height: height,
                width: double.infinity,
                child:
                    imageWidget ??
                    (imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder()),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: CleanTheme.imageOverlayGradient,
                  ),
                ),
              ),

              // Content at bottom
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),

                    // Rating and reviews
                    if (rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (ratingCount != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              ratingCount!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Favorite button
              if (onFavorite != null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFavorite
                            ? CleanTheme.accentRed
                            : CleanTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: CleanTheme.borderSecondary,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: CleanTheme.textTertiary,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN CHIP - Filter Pills
/// ═══════════════════════════════════════════════════════════
class CleanChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const CleanChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CleanTheme.quickDuration,
        curve: CleanTheme.smoothCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? CleanTheme.textPrimary : CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? CleanTheme.textPrimary
                : CleanTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? CleanTheme.surfaceColor
                    : CleanTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? CleanTheme.surfaceColor
                    : CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN SEARCH BAR - Rounded with icon
/// ═══════════════════════════════════════════════════════════
class CleanSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool showFilter;

  const CleanSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onFilterTap,
    this.showFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CleanTheme.borderPrimary, width: 1),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.search, color: CleanTheme.textTertiary, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  color: CleanTheme.textTertiary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (showFilter)
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.borderSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune,
                  color: CleanTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN AVATAR - User profile picture
/// ═══════════════════════════════════════════════════════════
class CleanAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;

  const CleanAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 44,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? CleanTheme.borderSecondary,
          border: showBorder
              ? Border.all(color: CleanTheme.borderPrimary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildInitials(),
                )
              : _buildInitials(),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials ?? '?',
        style: GoogleFonts.inter(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: CleanTheme.textSecondary,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN RATING - Star rating display
/// ═══════════════════════════════════════════════════════════
class CleanRating extends StatelessWidget {
  final double rating;
  final String? reviewCount;
  final bool showReviews;
  final double size;

  const CleanRating({
    super.key,
    required this.rating,
    this.reviewCount,
    this.showReviews = true,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: CleanTheme.textPrimary),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        if (showReviews && reviewCount != null) ...[
          const SizedBox(width: 8),
          Text(
            reviewCount!,
            style: GoogleFonts.inter(
              fontSize: size - 1,
              fontWeight: FontWeight.w400,
              color: CleanTheme.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN ICON BUTTON - Rounded icon button
/// ═══════════════════════════════════════════════════════════
class CleanIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool hasBorder;

  const CleanIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? CleanTheme.surfaceColor,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(color: CleanTheme.borderPrimary, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: iconColor ?? CleanTheme.textPrimary,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN BOTTOM NAV BAR - Modern navigation
/// ═══════════════════════════════════════════════════════════
class CleanBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CleanNavItem> items;

  const CleanBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: CleanTheme.borderPrimary, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: CleanTheme.quickDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CleanTheme.textPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 24,
                  color: isSelected
                      ? CleanTheme.surfaceColor
                      : CleanTheme.textTertiary,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class CleanNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const CleanNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN BADGE - Small status indicator
/// ═══════════════════════════════════════════════════════════
class CleanBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const CleanBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? CleanTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor ?? CleanTheme.primaryColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? CleanTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CLEAN SECTION HEADER - Title with action
/// ═══════════════════════════════════════════════════════════
class CleanSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const CleanSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CleanTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// FEATURED IMAGE CARD - Hero card with image and overlay
/// ═══════════════════════════════════════════════════════════
class FeaturedImageCard extends StatelessWidget {
  final String? imageUrl;
  final String? assetImage;
  final String title;
  final String? subtitle;
  final String? badge;
  final String? rating;
  final String? reviews;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double height;
  final double borderRadius;

  const FeaturedImageCard({
    super.key,
    this.imageUrl,
    this.assetImage,
    required this.title,
    this.subtitle,
    this.badge,
    this.rating,
    this.reviews,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.height = 280,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: CleanTheme.imageCardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (assetImage != null)
                Image.asset(
                  assetImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return Container(
                      color: CleanTheme.borderSecondary,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: CleanTheme.textTertiary,
                        ),
                      ),
                    );
                  },
                )
              else if (imageUrl != null)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: CleanTheme.borderSecondary,
                    child: const Icon(
                      Icons.image,
                      size: 48,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                )
              else
                Container(color: CleanTheme.textPrimary),

              // Gradient Overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: CleanTheme.imageOverlayGradient,
                ),
              ),

              // Favorite Button
              if (onFavorite != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? CleanTheme.accentRed
                            : CleanTheme.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // Content at bottom
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Rating and Reviews
                    Row(
                      children: [
                        if (rating != null) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        if (reviews != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            reviews!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Subtitle
                    if (subtitle != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subtitle!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: CleanTheme.textPrimary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// HORIZONTAL CHIPS - Scrollable category chips
/// ═══════════════════════════════════════════════════════════
class HorizontalChips extends StatelessWidget {
  final List<String> chips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry? padding;

  const HorizontalChips({
    super.key,
    required this.chips,
    required this.selectedIndex,
    required this.onSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? CleanTheme.textPrimary
                    : CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? CleanTheme.textPrimary
                      : CleanTheme.borderPrimary,
                  width: 1,
                ),
              ),
              child: Text(
                chips[index],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : CleanTheme.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// IMAGE CARD - Small card with image and info
/// ═══════════════════════════════════════════════════════════
class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final String? assetImage;
  final String title;
  final String? subtitle;
  final String? price;
  final String? rating;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double width;
  final double imageHeight;

  const ImageCard({
    super.key,
    this.imageUrl,
    this.assetImage,
    required this.title,
    this.subtitle,
    this.price,
    this.rating,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.width = 180,
    this.imageHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CleanTheme.borderPrimary),
          boxShadow: CleanTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: assetImage != null
                        ? Image.asset(assetImage!, fit: BoxFit.cover)
                        : imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: CleanTheme.borderSecondary,
                              child: const Icon(
                                Icons.image,
                                color: CleanTheme.textTertiary,
                              ),
                            ),
                          )
                        : Container(
                            color: CleanTheme.borderSecondary,
                            child: const Icon(
                              Icons.image,
                              color: CleanTheme.textTertiary,
                            ),
                          ),
                  ),
                ),

                // Favorite button
                if (onFavorite != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? CleanTheme.accentRed
                              : CleanTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      if (price != null)
                        Text(
                          price!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CIRCLE ICON BUTTON - Rounded icon button
/// ═══════════════════════════════════════════════════════════
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool hasBorder;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? CleanTheme.surfaceColor,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(color: CleanTheme.borderPrimary)
              : null,
          boxShadow: CleanTheme.cardShadow,
        ),
        child: Icon(
          icon,
          color: iconColor ?? CleanTheme.textPrimary,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// SCHEDULE CARD - Timeline/itinerary style card
/// ═══════════════════════════════════════════════════════════
class ScheduleCard extends StatelessWidget {
  final String day;
  final String title;
  final List<ScheduleItem> items;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const ScheduleCard({
    super.key,
    required this.day,
    required this.title,
    required this.items,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: CleanTheme.borderSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: CleanTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            const Divider(height: 1, color: CleanTheme.borderPrimary),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time indicator
                    SizedBox(
                      width: 50,
                      child: Text(
                        item.time,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ScheduleItem {
  final String time;
  final String description;

  const ScheduleItem({required this.time, required this.description});
}
