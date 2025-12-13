import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDCp5fx3V0z-AQ67Iei2dyjfGdB7wDsxsA8JsBIiiHFWJ3nJubaGLnM5YegD6sW48d-12qMfYfwWtWzl8BwCfGOIfl5_l8AE3xwZK7fY7RAbj6ZZASJaHQu0lhr0Fdakqw-IIrBj1GfAMYlYXbd0RBTAbhgsd4IUUKEj9-mcKq-2VmGF2pR3pQzdEgufvXLx_fJSdiOj826XkgdYtJl6SLI87ahV81t2pNEdsJBhU8R6lkif0UTaL6sr3H5NSXiLCGHuxwObD8xtLQ'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Logo
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: Color(0xFF13EC5B),
                      size: 40,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI.COACH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Headline
                const Text(
                  'Il Tuo Coach Personale,\nPotenziato dall\'AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Allenati in modo più intelligente con piani adattivi e correzioni in tempo reale.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                // Carousel
                SizedBox(
                  height: 200,
                  child: PageView(
                    children: [
                      _buildCarouselItem(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA-3FVZYWeG80O7_tyePg8hFJ4s-jlFQJHCP03K3uz7exEnNgReYZDmMZcfSvYyShbhZTnltYC5xpTp1_1Vo3aktytlOMCK5O3W9Jo79yxE_jRXkiqYkvJK_fRvL7T572CXXo1rDQUr7zTCRKjUo4k_u5cMKq0f3NZjdHmhmgTLxnSzCB0l8MguCfwXG5AYGWhIvWu6-YZaDhoFVgL_e3MWlU5jsTs8mLunHtFWzG193LV_JpbDryZ_D2h4-lW7K5Z2CMzwUO4YJ3s',
                        title: 'Piani su misura',
                        subtitle:
                            'Allenamenti creati apposta per il tuo corpo.',
                      ),
                      _buildCarouselItem(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuD2ORRGgaS09zakN1_OCwpUfxT_ndqcrYmZ-w8DDyhOh4Y9XjwmKX530IrbL4EZgNdJFYlPev7qbwO3YOrV0SU6KjdBHaQUpPyfLr4iVgOxxEGgpi7mpqXGTMvzRf7bulJcJDs5IflX85xhTUOTbQqKKQ4dhCrqNqov6kQ2j8kPAeJ8YToGlgMc98WLTszzb5m9BGjdtkIumwoQzeNBk1n4B6lcI1pJO5VHhAqDakoOB5PI8IaQFGNQCCzqqubsvUC7LEhi1ZSbgkc',
                        title: 'Correzione Live',
                        subtitle: 'Feedback immediato sulla tua postura.',
                      ),
                      _buildCarouselItem(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuD1zoOI3Gcwqk6bPYhl2cfjBmjVFiHg597dU-hujBf145h0yeUe0olbqVxRIto-sql1s6VLgbeUo4duIHaclkyrzTwlodMN0mhttWJRAoMkP9VDbgAd6-5iBoorob2Sp0V3urDBwRmrycxxOFBAy4KUW6_xCDkkhFzN-A1f36VmOl_RBvKpqO4NW0-B3eYCKq74QkKt75zBi6OnzekobTlr6UDcUK-WtEdagi4sUYrtS9OIckNILvCOFCkjZ2XZjwyxIHF2wWyrKxs',
                        title: 'Gamification',
                        subtitle: 'Raggiungi obiettivi sbloccando premi.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Handle create account
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF13EC5B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Crea Account',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // TODO: Handle login
                        },
                        child: const Text(
                          'Hai già un account? Accedi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem({
    required String imageUrl,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
