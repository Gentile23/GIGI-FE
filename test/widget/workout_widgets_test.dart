// Widget tests for Workout-related screens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createWidgetForTesting(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('Workout Card Widget Tests', () {
    testWidgets('Workout card displays title and info', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full Body Strength',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      const Text('45 min'),
                      const SizedBox(width: 16),
                      const Icon(Icons.fitness_center, size: 16),
                      const SizedBox(width: 4),
                      const Text('8 exercises'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Full Body Strength'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('8 exercises'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('Workout card with difficulty badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Upper Body Push'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Intermediate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Upper Body Push'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
    });
  });

  group('Exercise List Widget Tests', () {
    testWidgets('Exercise list shows all exercises', (
      WidgetTester tester,
    ) async {
      final exercises = ['Bench Press', 'Shoulder Press', 'Tricep Dips'];

      await tester.pumpWidget(
        createWidgetForTesting(
          ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(exercises[index]),
              subtitle: const Text('3 sets × 10 reps'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      );

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Shoulder Press'), findsOneWidget);
      expect(find.text('Tricep Dips'), findsOneWidget);
      expect(find.text('3 sets × 10 reps'), findsNWidgets(3));
    });

    testWidgets('Exercise with weight display', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
            title: const Text('Squat'),
            subtitle: const Text('4 sets × 8 reps @ 80kg'),
            trailing: Checkbox(value: true, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('4 sets × 8 reps @ 80kg'), findsOneWidget);
    });
  });

  group('Timer Display Widget Tests', () {
    testWidgets('Timer shows formatted time', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const Center(
            child: Text(
              '45:30',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );

      expect(find.text('45:30'), findsOneWidget);
    });

    testWidgets('Rest timer with progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Rest', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              const SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(value: 0.6, strokeWidth: 8),
              ),
              const SizedBox(height: 16),
              const Text('36s', style: TextStyle(fontSize: 36)),
            ],
          ),
        ),
      );

      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('36s'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Set Logging Widget Tests', () {
    testWidgets('Set logger shows reps and weight inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.check), onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Completed set display', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                const Text('Set 1: 10 reps @ 60kg'),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Edit')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Set 1: 10 reps @ 60kg'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });
  });

  group('Workout Summary Widget Tests', () {
    testWidgets('Summary shows workout stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            children: [
              const Text(
                'Workout Complete! 🎉',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Duration', '45:30'),
                  _buildStatColumn('Exercises', '8'),
                  _buildStatColumn('Total Sets', '24'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Volume', '5,280 kg'),
                  _buildStatColumn('Calories', '~320 kcal'),
                  _buildStatColumn('XP Earned', '+150'),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Workout Complete! 🎉'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('45:30'), findsOneWidget);
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('5,280 kg'), findsOneWidget);
    });
  });

  group('Progress Indicator Widget Tests', () {
    testWidgets('Workout progress bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text('Progress'), const Text('5/8 exercises')],
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(value: 0.625),
            ],
          ),
        ),
      );

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('5/8 exercises'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('Empty State Widget Tests', () {
    testWidgets('No workouts empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No workouts yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate your first AI workout plan!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Plan'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No workouts yet'), findsOneWidget);
      expect(find.text('Generate your first AI workout plan!'), findsOneWidget);
      expect(find.text('Generate Plan'), findsOneWidget);
    });
  });
}

Widget _buildStatColumn(String label, String value) {
  return Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.grey[600])),
    ],
  );
}
