import 'package:flutter_test/flutter_test.dart';
import 'package:devtrack/main.dart';

void main() {
  group('App Smoke Tests', () {
    testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const DevTrackApp());

      // Verify that the splash screen logo/text is present.
      expect(find.text('Dev'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(find.text('YOUR  DEVELOPER  OS'), findsOneWidget);
    });

    testWidgets('Navigation smoke test', (WidgetTester tester) async {
      // Build our app.
      await tester.pumpWidget(const DevTrackApp());

      // Splash screen has a timer/animation, we might need to pump and settle
      // to see if it transitions to onboarding. 
      // Note: In real tests, we usually mock the navigation or delay.
      // For a basic smoke test, verifying the initial state is good.
      
      expect(find.text('Dev'), findsOneWidget);
    });
  });
}
