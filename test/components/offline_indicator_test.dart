import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everyday_christian/components/offline_indicator.dart';
import 'package:everyday_christian/core/providers/app_providers.dart';

void main() {
  group('OfflineIndicator', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: OfflineIndicator(
              child: Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('shows offline badge when disconnected', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(false),
            ),
          ],
          child: const MaterialApp(
            home: OfflineIndicator(
              child: Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Wait for async provider to resolve
      await tester.pumpAndSettle();

      // Should show offline indicator
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('hides offline badge when connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: OfflineIndicator(
              child: Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Wait for async provider to resolve
      await tester.pumpAndSettle();

      // Should not show offline indicator
      expect(find.text('Offline'), findsNothing);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });

    testWidgets('toggles badge on connectivity changes', (WidgetTester tester) async {
      // Start offline
      final container = ProviderContainer(
        overrides: [
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value(false),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OfflineIndicator(
              child: Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);

      // Change to online
      container.updateOverrides([
        connectivityStatusProvider.overrideWith(
          (ref) => Stream.value(true),
        ),
      ]);

      container.invalidate(connectivityStatusProvider);
      await tester.pumpAndSettle();

      // Should hide offline indicator
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('badge is positioned in top-right corner', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(false),
            ),
          ],
          child: const MaterialApp(
            home: OfflineIndicator(
              child: Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Positioned widget
      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.text('Offline'),
          matching: find.byType(Positioned),
        ),
      );

      // Verify it's positioned in top-right
      expect(positioned.right, 16);
      expect(positioned.top, isNotNull);
    });

    testWidgets('handles loading state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.fromFuture(
                Future.delayed(const Duration(milliseconds: 100), () => true),
              ),
            ),
          ],
          child: const MaterialApp(
            home: OfflineIndicator(
              child: Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // During loading, should not show offline badge
      await tester.pump();
      expect(find.text('Offline'), findsNothing);
      expect(find.text('Test Child'), findsOneWidget);

      // Wait for future to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // After loading, still should not show badge (connected)
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('handles error state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.error('Test error'),
            ),
          ],
          child: const MaterialApp(
            home: OfflineIndicator(
              child: Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On error, should not show offline badge (fail gracefully)
      expect(find.text('Offline'), findsNothing);
      expect(find.text('Test Child'), findsOneWidget);
    });
  });
}
