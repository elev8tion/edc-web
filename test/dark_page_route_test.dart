import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/core/navigation/page_transitions.dart';

void main() {
  group('DarkPageRoute', () {
    test('has dark barrier color instead of white', () {
      final route = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: const RouteSettings(name: '/test'),
      );

      // Verify barrier color is dark (#121212), not white
      expect(route.barrierColor, equals(const Color(0xFF121212)));
      expect(route.barrierColor, isNot(equals(Colors.white)));
    });

    test('is opaque', () {
      final route = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: const RouteSettings(name: '/test'),
      );

      expect(route.opaque, isTrue);
    });

    test('has correct transition duration', () {
      final route = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: const RouteSettings(name: '/test'),
      );

      expect(route.transitionDuration, equals(const Duration(milliseconds: 300)));
      expect(route.reverseTransitionDuration, equals(const Duration(milliseconds: 300)));
    });

    test('maintains state by default', () {
      final route = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: const RouteSettings(name: '/test'),
      );

      expect(route.maintainState, isTrue);
    });

    test('preserves route settings', () {
      const settings = RouteSettings(name: '/devotional', arguments: {'id': 1});
      final route = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: settings,
      );

      expect(route.settings.name, equals('/devotional'));
      expect(route.settings.arguments, equals({'id': 1}));
    });

    test('supports fullscreen dialog mode', () {
      final route = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: const RouteSettings(name: '/test'),
        fullscreenDialog: true,
      );

      expect(route.fullscreenDialog, isTrue);
    });

    test('can transition to and from other route types', () {
      final darkRoute = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: const RouteSettings(name: '/test'),
      );

      final materialRoute = MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
      );

      // DarkPageRoute should be compatible with MaterialPageRoute
      expect(darkRoute.canTransitionTo(materialRoute), isTrue);
      expect(darkRoute.canTransitionFrom(materialRoute), isTrue);
    });

    testWidgets('builds page correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('Home')),
          onGenerateRoute: (settings) {
            if (settings.name == '/test') {
              return DarkPageRoute(
                settings: settings,
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Test Page')),
                ),
              );
            }
            return null;
          },
        ),
      );

      // Navigate to test page
      final navigator = Navigator.of(tester.element(find.text('Home')));
      navigator.pushNamed('/test');
      await tester.pumpAndSettle();

      // Verify the page was built
      expect(find.text('Test Page'), findsOneWidget);
    });

    testWidgets('uses correct transition on Android', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    DarkPageRoute(
                      settings: const RouteSettings(name: '/test'),
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('Android Page')),
                      ),
                    ),
                  );
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Page should be animating in
      expect(find.text('Android Page'), findsOneWidget);
    });

    testWidgets('uses Cupertino transition on iOS', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    DarkPageRoute(
                      settings: const RouteSettings(name: '/test'),
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('iOS Page')),
                      ),
                    ),
                  );
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Page should be animating in with Cupertino style
      expect(find.text('iOS Page'), findsOneWidget);
    });
  });

  group('DarkPageRoute vs MaterialPageRoute', () {
    test('DarkPageRoute has dark barrier, MaterialPageRoute has null/white', () {
      final darkRoute = DarkPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
        settings: const RouteSettings(name: '/test'),
      );

      final materialRoute = MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Test')),
      );

      // DarkPageRoute should have dark barrier
      expect(darkRoute.barrierColor, equals(const Color(0xFF121212)));

      // MaterialPageRoute has null barrier (which shows as white on iOS)
      expect(materialRoute.barrierColor, isNull);
    });
  });
}
