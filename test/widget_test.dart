import 'package:flutter_test/flutter_test.dart';
import 'package:GIGI/main.dart';
import 'package:GIGI/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('App starts with Onboarding screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GigiApp());

    // Verify that OnboardingScreen is present
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Verify initial slide content
    expect(find.text('AI Coach for Your Fitness Journey'), findsOneWidget);
    expect(
      find.text('Get Started'),
      findsNothing,
    ); // Should be 'Next' initially

    // Tap 'Next' button
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle(); // Wait for animation

    // Verify second slide
    expect(find.text('3 Assessment Workouts to Start'), findsOneWidget);
  });
}
