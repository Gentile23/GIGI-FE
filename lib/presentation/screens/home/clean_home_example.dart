import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';

/// Example Home Screen with Clean Design
/// Inspired by travel app UI
class CleanHomeExample extends StatefulWidget {
  const CleanHomeExample({super.key});

  @override
  State<CleanHomeExample> createState() => _CleanHomeExampleState();
}

class _CleanHomeExampleState extends State<CleanHomeExample> {
  int _selectedCategoryIndex = 2; // "South America" selected by default
  int _bottomNavIndex = 0;

  final List<String> _categories = [
    'Asia',
    'Europe',
    'Strength',
    'Cardio',
    'HIIT',
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CleanTheme.lightTheme,
      child: Scaffold(
        backgroundColor: CleanTheme.backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════════════════════
                  // HEADER - Greeting with avatar
                  // ═══════════════════════════════════════════════════════════
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, Marco 👋',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Welcome to GIGI',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const CleanAvatar(initials: 'MR', size: 48),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // SEARCH BAR
                  // ═══════════════════════════════════════════════════════════
                  const CleanSearchBar(hintText: 'Cerca workout, esercizi...'),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // SECTION - Select your workout type
                  // ═══════════════════════════════════════════════════════════
                  Text(
                    'Scegli il tuo workout',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_categories.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: CleanChip(
                            label: _categories[index],
                            isSelected: _selectedCategoryIndex == index,
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════════════════
                  // MAIN WORKOUT CARD - Full width with image
                  // ═══════════════════════════════════════════════════════════
                  CleanImageCard(
                    imageWidget: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade700,
                            Colors.purple.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    title: 'Full Body Workout',
                    badge: 'Personalizzato',
                    rating: 5.0,
                    ratingCount: '143 reviews',
                    height: 220,
                    onFavorite: () {},
                    isFavorite: true,
                    onTap: () {
                      // Navigate to workout details
                    },
                  ),

                  const SizedBox(height: 12),

                  // See more button
                  Center(
                    child: CleanButton(
                      text: 'Vedi altro',
                      trailingIcon: Icons.chevron_right,
                      isOutlined: true,
                      onPressed: () {},
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════════════════════
                  // SECTION - Upcoming workouts
                  // ═══════════════════════════════════════════════════════════
                  const CleanSectionHeader(
                    title: 'I tuoi prossimi workout',
                    actionText: 'Vedi tutti',
                  ),

                  const SizedBox(height: 16),

                  // Horizontal list of workout cards
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMiniWorkoutCard(
                          title: 'Push Day',
                          duration: '45 min',
                          exercises: 6,
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(width: 12),
                        _buildMiniWorkoutCard(
                          title: 'Pull Day',
                          duration: '50 min',
                          exercises: 7,
                          color: Colors.teal.shade400,
                        ),
                        const SizedBox(width: 12),
                        _buildMiniWorkoutCard(
                          title: 'Leg Day',
                          duration: '55 min',
                          exercises: 8,
                          color: Colors.pink.shade400,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════════════════════
                  // SECTION - Quick Stats
                  // ═══════════════════════════════════════════════════════════
                  const CleanSectionHeader(title: 'Le tue statistiche'),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department_rounded,
                          value: '1,250',
                          label: 'Calorie bruciate',
                          color: CleanTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer_outlined,
                          value: '12h',
                          label: 'Tempo totale',
                          color: CleanTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.fitness_center,
                          value: '28',
                          label: 'Workout completati',
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.emoji_events_rounded,
                          value: '5',
                          label: 'Badge guadagnati',
                          color: CleanTheme.accentYellow,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════════════════════
                  // CTA CARD - Trial Workout
                  // ═══════════════════════════════════════════════════════════
                  CleanCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CleanTheme.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: CleanTheme.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inizia il Trial Workout',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prova un allenamento personalizzato',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CleanIconButton(
                          icon: Icons.arrow_forward,
                          size: 40,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // BOTTOM NAVIGATION
        // ═══════════════════════════════════════════════════════════
        bottomNavigationBar: CleanBottomNavBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
            });
          },
          items: const [
            CleanNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            CleanNavItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              label: 'Schedule',
            ),
            CleanNavItem(
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
              label: 'Favorites',
            ),
            CleanNavItem(
              icon: Icons.more_horiz,
              activeIcon: Icons.more_horiz,
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniWorkoutCard({
    required String title,
    required String duration,
    required int exercises,
    required Color color,
  }) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: CleanTheme.imageCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background with color
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$duration · $exercises exercises',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CleanRating(rating: 4.6, size: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Favorite button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
