import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/components/dancing_logo_loader.dart';

void main() {
  group('DancingLogoLoader', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(size: 100),
          ),
        ),
      );

      expect(find.byType(DancingLogoLoader), findsOneWidget);
    });

    testWidgets('respects size parameter', (WidgetTester tester) async {
      const testSize = 150.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(size: testSize),
          ),
        ),
      );

      final container = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );

      expect(container.width, testSize);
      expect(container.height, testSize);
    });

    testWidgets('animation controller initializes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(size: 100),
          ),
        ),
      );

      // Pump frames to start animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify widget is still present after animation start
      expect(find.byType(DancingLogoLoader), findsOneWidget);
    });

    testWidgets('supports different language codes', (WidgetTester tester) async {
      // Test English
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(size: 100, languageCode: 'en'),
          ),
        ),
      );
      expect(find.byType(DancingLogoLoader), findsOneWidget);

      // Test Spanish
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(size: 100, languageCode: 'es'),
          ),
        ),
      );
      expect(find.byType(DancingLogoLoader), findsOneWidget);
    });

    testWidgets('renders animation components', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(size: 100),
          ),
        ),
      );

      await tester.pump();

      // Verify animation components are present (at least some)
      final animatedBuilders = find.byType(AnimatedBuilder);
      expect(animatedBuilders, findsWidgets);
    });

    testWidgets('custom duration works', (WidgetTester tester) async {
      const customDuration = Duration(seconds: 3);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(
              size: 100,
              duration: customDuration,
            ),
          ),
        ),
      );

      expect(find.byType(DancingLogoLoader), findsOneWidget);
    });

    testWidgets('disposes animation controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DancingLogoLoader(size: 100),
          ),
        ),
      );

      expect(find.byType(DancingLogoLoader), findsOneWidget);

      // Remove widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Should not throw errors after disposal
      expect(find.byType(DancingLogoLoader), findsNothing);
    });
  });
}
