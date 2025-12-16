import 'package:flutter_test/flutter_test.dart';
import 'package:gigi/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GigiApp());

    // Verify app loads without errors
    expect(find.byType(GigiApp), findsOneWidget);
  });
}
