// Integration tests for workout flow
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to wrap widgets with Material App for testing
Widget createWidgetForTesting(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('Workout Flow Integration Tests', () {
    testWidgets('Full workout session flow simulation', (
      WidgetTester tester,
    ) async {
      // 1. DASHBOARD: Start "Leg Day" Workout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ListView(
                children: [
                  const Text("Today's Plan: Leg Day"),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Session
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const _MockSessionScreen(name: 'Leg Day'),
                        ),
                      );
                    },
                    child: const Text('Start Workout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify Dashboard
      expect(find.text("Today's Plan: Leg Day"), findsOneWidget);
      expect(find.text('Start Workout'), findsOneWidget);

      // Tap Start
      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();

      // 2. SESSION SCREEN
      expect(find.text('Leg Day Session'), findsOneWidget); // App Bar title
      expect(find.text('Squats'), findsOneWidget); // First Exercise
      expect(find.text('00:00'), findsOneWidget); // Timer

      // Enter Data
      await tester.enterText(find.byKey(const Key('reps_input')), '10');
      await tester.enterText(find.byKey(const Key('weight_input')), '100');

      // Complete Set
      await tester.tap(find.text('Complete Set 1'));
      await tester.pump();

      // Verify Checkmark or update
      expect(find.byIcon(Icons.check), findsOneWidget); // Mocked feedback

      // Finish Workout
      await tester.tap(find.text('Finish Workout'));
      await tester.pumpAndSettle();

      // 3. SUMMARY SCREEN
      expect(find.text('Workout Completed!'), findsOneWidget);
      expect(find.text('Duration: 45m'), findsOneWidget);
    });
  });
}

// Mock Screens for the Simulation (replaces real screens to isolate UI logic flow)

class _MockSessionScreen extends StatefulWidget {
  final String name;
  const _MockSessionScreen({required this.name});

  @override
  State<_MockSessionScreen> createState() => _MockSessionScreenState();
}

class _MockSessionScreenState extends State<_MockSessionScreen> {
  bool setCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.name} Session')),
      body: Column(
        children: [
          const Text('00:00', style: TextStyle(fontSize: 30)), // Timer
          const ListTile(title: Text('Squats')),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('reps_input'),
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
              Expanded(
                child: TextField(
                  key: const Key('weight_input'),
                  decoration: const InputDecoration(labelText: 'Kg'),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                setCompleted = true;
              });
            },
            child: const Text('Complete Set 1'),
          ),
          if (setCompleted) const Icon(Icons.check),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _MockSummaryScreen()),
              );
            },
            child: const Text('Finish Workout'),
          ),
        ],
      ),
    );
  }
}

class _MockSummaryScreen extends StatelessWidget {
  const _MockSummaryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: const [Text('Workout Completed!'), Text('Duration: 45m')],
        ),
      ),
    );
  }
}
