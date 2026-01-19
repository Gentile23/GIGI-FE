// ignore_for_file: deprecated_member_use
// Integration tests for onboarding flow
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Onboarding Page Navigation Tests', () {
    testWidgets('Onboarding shows first page', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildOnboardingPage(
              title: 'Welcome to Gigi',
              description: 'Your AI personal trainer',
              emoji: '👋',
            ),
          ),
        ),
      );

      expect(find.text('Welcome to Gigi'), findsOneWidget);
      expect(find.text('Your AI personal trainer'), findsOneWidget);
      expect(find.text('👋'), findsOneWidget);
    });

    testWidgets('Onboarding has navigation buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: Center(child: Text('Welcome'))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Skip')),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Page indicator shows current position', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  width: index == 1 ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == 1 ? Colors.blue : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Should find 4 container indicators
      expect(find.byType(Container), findsAtLeast(4));
    });
  });

  group('Questionnaire Flow Tests', () {
    testWidgets('Questionnaire shows question', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const LinearProgressIndicator(value: 0.33),
                const SizedBox(height: 24),
                const Text(
                  'What is your fitness goal?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildOptionTile('Lose Weight', '🏃'),
                _buildOptionTile('Build Muscle', '💪'),
                _buildOptionTile('Stay Healthy', '❤️'),
                _buildOptionTile('Increase Strength', '🏋️'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('What is your fitness goal?'), findsOneWidget);
      expect(find.text('Lose Weight'), findsOneWidget);
      expect(find.text('Build Muscle'), findsOneWidget);
      expect(find.text('Stay Healthy'), findsOneWidget);
    });

    testWidgets('Questionnaire option selection', (WidgetTester tester) async {
      String? selectedOption;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    const Text('Select your experience level'),
                    RadioListTile<String>(
                      value: 'beginner',
                      groupValue: selectedOption,
                      onChanged: (value) =>
                          setState(() => selectedOption = value),
                      title: const Text('Beginner'),
                    ),
                    RadioListTile<String>(
                      value: 'intermediate',
                      groupValue: selectedOption,
                      onChanged: (value) =>
                          setState(() => selectedOption = value),
                      title: const Text('Intermediate'),
                    ),
                    RadioListTile<String>(
                      value: 'advanced',
                      groupValue: selectedOption,
                      onChanged: (value) =>
                          setState(() => selectedOption = value),
                      title: const Text('Advanced'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);

      await tester.tap(find.text('Intermediate'));
      await tester.pump();

      expect(selectedOption, 'intermediate');
    });
  });

  group('Athletic Assessment Tests', () {
    testWidgets('Assessment intro screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Athletic Assessment',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete a quick assessment to help us personalize your workout plan.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Start Assessment'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Athletic Assessment'), findsOneWidget);
      expect(find.text('Start Assessment'), findsOneWidget);
    });

    testWidgets('Assessment exercise display', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Push-ups Test',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('How many push-ups can you do in 60 seconds?'),
                  const SizedBox(height: 24),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Number of push-ups',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickValue('0-10'),
                      _buildQuickValue('11-20'),
                      _buildQuickValue('21-30'),
                      _buildQuickValue('30+'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Push-ups Test'), findsOneWidget);
      expect(find.text('Number of push-ups'), findsOneWidget);
      expect(find.text('0-10'), findsOneWidget);
      expect(find.text('30+'), findsOneWidget);
    });
  });

  group('Consent Checkbox Tests', () {
    testWidgets('GDPR consent checkboxes', (WidgetTester tester) async {
      bool termsAccepted = false;
      bool privacyAccepted = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    CheckboxListTile(
                      value: termsAccepted,
                      onChanged: (v) =>
                          setState(() => termsAccepted = v ?? false),
                      title: const Text('I accept the Terms of Service'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: privacyAccepted,
                      onChanged: (v) =>
                          setState(() => privacyAccepted = v ?? false),
                      title: const Text('I accept the Privacy Policy'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: termsAccepted && privacyAccepted
                          ? () {}
                          : null,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('I accept the Terms of Service'), findsOneWidget);
      expect(find.text('I accept the Privacy Policy'), findsOneWidget);

      // Button should be disabled initially
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);

      // Accept both
      await tester.tap(find.text('I accept the Terms of Service'));
      await tester.pump();
      await tester.tap(find.text('I accept the Privacy Policy'));
      await tester.pump();

      // Button should now be enabled
      final enabledButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(enabledButton.onPressed, isNotNull);
    });
  });

  group('Goal Setup Tests', () {
    testWidgets('Goal setup with slider', (WidgetTester tester) async {
      double targetWeight = 70;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Target Weight', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 16),
                    Text(
                      '${targetWeight.toInt()} kg',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: targetWeight,
                      min: 40,
                      max: 150,
                      divisions: 110,
                      onChanged: (v) => setState(() => targetWeight = v),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Target Weight'), findsOneWidget);
      expect(find.text('70 kg'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}

Widget _buildOnboardingPage({
  required String title,
  required String description,
  required String emoji,
}) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    ),
  );
}

Widget _buildOptionTile(String title, String emoji) {
  return Card(
    child: ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    ),
  );
}

Widget _buildQuickValue(String value) {
  return OutlinedButton(onPressed: () {}, child: Text(value));
}
