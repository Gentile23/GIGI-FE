// Widget tests for Nutrition-related screens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createWidgetForTesting(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('Macro Progress Widget Tests', () {
    testWidgets('Macro ring shows progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '1500',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('/ 2000 kcal'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('1500'), findsOneWidget);
      expect(find.text('/ 2000 kcal'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Macro breakdown bars', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            children: [
              _buildMacroBar('Protein', 120, 150, Colors.red),
              const SizedBox(height: 12),
              _buildMacroBar('Carbs', 180, 200, Colors.blue),
              const SizedBox(height: 12),
              _buildMacroBar('Fat', 50, 65, Colors.orange),
            ],
          ),
        ),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('120g / 150g'), findsOneWidget);
      expect(find.text('180g / 200g'), findsOneWidget);
      expect(find.text('50g / 65g'), findsOneWidget);
    });
  });

  group('Meal Card Widget Tests', () {
    testWidgets('Meal card displays meal info', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.restaurant, color: Colors.white),
              ),
              title: const Text('Lunch'),
              subtitle: const Text('Chicken Salad - 450 kcal'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      );

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Chicken Salad - 450 kcal'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('Meal with macros display', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grilled Chicken Breast',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMacroChip('P: 40g', Colors.red),
                      const SizedBox(width: 8),
                      _buildMacroChip('C: 5g', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMacroChip('F: 8g', Colors.orange),
                      const Spacer(),
                      const Text(
                        '280 kcal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Grilled Chicken Breast'), findsOneWidget);
      expect(find.text('P: 40g'), findsOneWidget);
      expect(find.text('C: 5g'), findsOneWidget);
      expect(find.text('F: 8g'), findsOneWidget);
      expect(find.text('280 kcal'), findsOneWidget);
    });
  });

  group('Water Tracker Widget Tests', () {
    testWidgets('Water tracker shows glasses', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            children: [
              const Text(
                'Water Intake',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  8,
                  (index) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.local_drink,
                      color: index < 5 ? Colors.blue : Colors.grey[300],
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('5/8 glasses (1.25L)'),
            ],
          ),
        ),
      );

      expect(find.text('Water Intake'), findsOneWidget);
      expect(find.text('5/8 glasses (1.25L)'), findsOneWidget);
      expect(find.byIcon(Icons.local_drink), findsNWidgets(8));
    });

    testWidgets('Add water button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Glass'),
          ),
        ),
      );

      expect(find.text('Add Glass'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('Meal Log Widget Tests', () {
    testWidgets('Empty meal log shows add button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Card(
            child: InkWell(
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text('Add Breakfast'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Add Breakfast'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('Logged meal with edit/delete options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Card(
            child: ListTile(
              title: const Text('Oatmeal with Berries'),
              subtitle: const Text('350 kcal • 8:30 AM'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(child: Text('Edit')),
                  const PopupMenuItem(child: Text('Delete')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Oatmeal with Berries'), findsOneWidget);
      expect(find.text('350 kcal • 8:30 AM'), findsOneWidget);
      expect(find.byType(PopupMenuButton<dynamic>), findsOneWidget);
    });
  });

  group('Nutrition Summary Widget Tests', () {
    testWidgets('Daily summary card', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Eaten', '1,650', 'kcal'),
                      _buildSummaryItem('Remaining', '350', 'kcal'),
                      _buildSummaryItem('Goal', '2,000', 'kcal'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text("Today's Summary"), findsOneWidget);
      expect(find.text('Eaten'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
    });
  });

  group('AI Meal Scan Widget Tests', () {
    testWidgets('Scan button and camera preview placeholder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Scan Meal'),
              ),
              const SizedBox(height: 8),
              const Text('AI will analyze your meal and estimate calories'),
            ],
          ),
        ),
      );

      expect(find.text('Scan Meal'), findsOneWidget);
      expect(
        find.text('AI will analyze your meal and estimate calories'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });

  group('Quick Add Buttons Widget Tests', () {
    testWidgets('Quick add meal buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.free_breakfast),
                label: const Text('Breakfast'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.lunch_dining),
                label: const Text('Lunch'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.dinner_dining),
                label: const Text('Dinner'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.cookie),
                label: const Text('Snack'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Snack'), findsOneWidget);
    });
  });
}

Widget _buildMacroBar(String label, int current, int goal, Color color) {
  return Row(
    children: [
      SizedBox(width: 60, child: Text(label)),
      Expanded(
        child: LinearProgressIndicator(
          value: current / goal,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
      const SizedBox(width: 8),
      Text('${current}g / ${goal}g'),
    ],
  );
}

Widget _buildMacroChip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 12)),
  );
}

Widget _buildSummaryItem(String label, String value, String unit) {
  return Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      Text(unit, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.grey[600])),
    ],
  );
}
