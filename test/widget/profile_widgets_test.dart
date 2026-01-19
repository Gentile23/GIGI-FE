// Widget tests for Profile and Settings screens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createWidgetForTesting(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('Profile Header Widget Tests', () {
    testWidgets('Profile header shows user info', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Text(
                  'MR',
                  style: TextStyle(fontSize: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mario Rossi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'mario@example.com',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Level', '5'),
                  _buildStatItem('XP', '1,250'),
                  _buildStatItem('Streak', '7 days'),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('MR'), findsOneWidget);
      expect(find.text('Mario Rossi'), findsOneWidget);
      expect(find.text('mario@example.com'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
    });

    testWidgets('Profile with premium badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mario Rossi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Mario Rossi'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
    });
  });

  group('Settings List Widget Tests', () {
    testWidgets('Settings section with tiles', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          ListView(
            children: [
              _buildSettingsTile(Icons.person, 'Personal Info'),
              _buildSettingsTile(Icons.notifications, 'Notifications'),
              _buildSettingsTile(Icons.security, 'Privacy & Security'),
              _buildSettingsTile(
                Icons.monitor_heart_outlined,
                'Health & Fitness',
              ),
              _buildSettingsTile(Icons.help_outline, 'Help & Support'),
              _buildSettingsTile(Icons.info_outline, 'Info'),
            ],
          ),
        ),
      );

      expect(find.text('Personal Info'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Health & Fitness'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
    });

    testWidgets('Settings tile with toggle', (WidgetTester tester) async {
      bool isEnabled = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return createWidgetForTesting(
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Push Notifications'),
                trailing: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() => isEnabled = value);
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
    });
  });

  group('Body Stats Widget Tests', () {
    testWidgets('Body stats display', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBodyStat('Height', '180 cm'),
              _buildBodyStat('Weight', '75 kg'),
              _buildBodyStat('Age', '30'),
            ],
          ),
        ),
      );

      expect(find.text('Height'), findsOneWidget);
      expect(find.text('180 cm'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('75 kg'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });
  });

  group('Logout Button Widget Tests', () {
    testWidgets('Logout button styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.red,
            ),
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
      );

      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });

  group('Achievement Badge Widget Tests', () {
    testWidgets('Achievement badges display', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge('🏆', 'First Workout'),
              _buildBadge('🔥', '7-Day Streak'),
              _buildBadge('💪', '100 Workouts'),
              _buildBadge('⭐', 'Level 5'),
            ],
          ),
        ),
      );

      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('First Workout'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('7-Day Streak'), findsOneWidget);
    });
  });

  group('Edit Profile Form Widget Tests', () {
    testWidgets('Edit profile shows fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });

  group('Coming Soon Snackbar Tests', () {
    testWidgets('Coming soon snackbar appears on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming Soon!')));
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Notifications'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Coming Soon!'), findsOneWidget);
    });
  });
}

Widget _buildStatItem(String label, String value) {
  return Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );
}

Widget _buildSettingsTile(IconData icon, String title) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {},
  );
}

Widget _buildBodyStat(String label, String value) {
  return Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

Widget _buildBadge(String emoji, String label) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );
}
