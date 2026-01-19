// Widget tests for common UI components
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test helper to wrap widgets with MaterialApp
Widget createWidgetForTesting(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('Button Widget Tests', () {
    testWidgets('ElevatedButton renders correctly', (
      WidgetTester tester,
    ) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        createWidgetForTesting(
          ElevatedButton(
            onPressed: () => wasPressed = true,
            child: const Text('Test Button'),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(wasPressed, true);
    });

    testWidgets('Disabled button is not tappable', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        createWidgetForTesting(
          ElevatedButton(
            onPressed: null, // Disabled
            child: const Text('Disabled Button'),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(wasPressed, false);
    });
  });

  group('TextField Widget Tests', () {
    testWidgets('TextField accepts input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        createWidgetForTesting(
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test@example.com');
      expect(controller.text, 'test@example.com');
    });

    testWidgets('TextField shows error text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: 'Invalid email address',
            ),
          ),
        ),
      );

      expect(find.text('Invalid email address'), findsOneWidget);
    });

    testWidgets('Password field obscures text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });
  });

  group('Checkbox Widget Tests', () {
    testWidgets('Checkbox toggles correctly', (WidgetTester tester) async {
      bool isChecked = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return createWidgetForTesting(
              Checkbox(
                value: isChecked,
                onChanged: (value) {
                  setState(() => isChecked = value!);
                },
              ),
            );
          },
        ),
      );

      expect(isChecked, false);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // After tap, the checkbox should be checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });
  });

  group('Card Widget Tests', () {
    testWidgets('Card renders with child content', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('Card with elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const Card(elevation: 8.0, child: Text('Elevated Card')),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 8.0);
    });
  });

  group('ListView Widget Tests', () {
    testWidgets('ListView scrolls correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) =>
                ListTile(title: Text('Item $index')),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 19'), findsNothing); // Not visible yet

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // After scrolling, later items should be visible
      expect(find.text('Item 0'), findsNothing);
    });
  });

  group('BottomNavigationBar Widget Tests', () {
    testWidgets('BottomNavigationBar changes index on tap', (
      WidgetTester tester,
    ) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: const Center(child: Text('Content')),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() => currentIndex = index);
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.fitness_center),
                      label: 'Workout',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(currentIndex, 0);

      await tester.tap(find.text('Workout'));
      await tester.pump();

      expect(currentIndex, 1);
    });
  });

  group('Progress Indicator Tests', () {
    testWidgets('CircularProgressIndicator renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetForTesting(const CircularProgressIndicator()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LinearProgressIndicator shows progress', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetForTesting(const LinearProgressIndicator(value: 0.5)),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.5);
    });
  });

  group('Icon Button Tests', () {
    testWidgets('IconButton responds to tap', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        createWidgetForTesting(
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => wasPressed = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      expect(wasPressed, true);
    });
  });

  group('SnackBar Tests', () {
    testWidgets('SnackBar displays message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test SnackBar')),
                  );
                },
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump(); // Start animation
      await tester.pump(
        const Duration(milliseconds: 750),
      ); // Complete animation

      expect(find.text('Test SnackBar'), findsOneWidget);
    });
  });

  group('AlertDialog Tests', () {
    testWidgets('AlertDialog shows title and message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text('Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap OK to close
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
    });
  });
}
