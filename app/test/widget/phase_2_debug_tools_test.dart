import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/devtools/demo_fixture_models.dart';
import 'package:training_log_app/devtools/demo_fixture_service.dart';
import 'package:training_log_app/features/home/home_screen.dart';

import '../test_helpers/localized_test_app.dart';

class _MockDemoFixtureService extends Mock implements DemoFixtureService {}

void main() {
  setUpAll(() {
    registerFallbackValue(DemoFixtureScenario.baseRealistic);
  });

  testWidgets(
    'debug tools entry is visible but tools stay hidden on Other screen',
    (tester) async {
      final service = _MockDemoFixtureService();
      when(
        () => service.resetAndSeed(any(), now: any(named: 'now')),
      ).thenAnswer((_) async {});
      when(() => service.resetAllData()).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoFixtureServiceProvider.overrideWithValue(service),
            appClockProvider.overrideWithValue(
              () => DateTime(2026, 2, 23, 9, 30),
            ),
          ],
          child: localizedTestApp(
            home: const Scaffold(body: OtherTabContent()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('other_debug_tools_item')), findsOneWidget);
      expect(find.text('Debug tools'), findsOneWidget);
      expect(find.byKey(const Key('other_debug_tools')), findsNothing);
      expect(find.byKey(const Key('debug_seed_demo_data')), findsNothing);
      expect(find.byKey(const Key('debug_reset_all_data')), findsNothing);
    },
  );

  testWidgets('wrong password keeps debug tools locked', (tester) async {
    final service = _MockDemoFixtureService();
    when(
      () => service.resetAndSeed(any(), now: any(named: 'now')),
    ).thenAnswer((_) async {});
    when(() => service.resetAllData()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoFixtureServiceProvider.overrideWithValue(service),
          appClockProvider.overrideWithValue(
            () => DateTime(2026, 2, 23, 9, 30),
          ),
        ],
        child: localizedTestApp(home: const Scaffold(body: OtherTabContent())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('other_debug_tools_item')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('debug_tools_password_field')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('debug_tools_password_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect password'), findsOneWidget);
    expect(find.byKey(const Key('other_debug_tools')), findsNothing);
    verifyNever(() => service.resetAndSeed(any(), now: any(named: 'now')));
    verifyNever(() => service.resetAllData());
  });

  testWidgets(
    'correct password opens debug tools page and requires re-entry after exit',
    (tester) async {
      final service = _MockDemoFixtureService();
      final fixedNow = DateTime(2026, 2, 23, 9, 30);
      when(
        () => service.resetAndSeed(any(), now: any(named: 'now')),
      ).thenAnswer((_) async {});
      when(() => service.resetAllData()).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoFixtureServiceProvider.overrideWithValue(service),
            appClockProvider.overrideWithValue(() => fixedNow),
          ],
          child: localizedTestApp(
            home: const Scaffold(body: OtherTabContent()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('other_debug_tools_item')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('debug_tools_password_field')),
        'DevAccess',
      );
      await tester.tap(find.byKey(const Key('debug_tools_password_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Debug tools'), findsNWidgets(2));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byKey(const Key('other_debug_tools')), findsOneWidget);

      await tester.tap(find.byKey(const Key('debug_seed_demo_data')));
      await tester.pumpAndSettle();

      verify(
        () => service.resetAndSeed(
          DemoFixtureScenario.baseRealistic,
          now: fixedNow,
        ),
      ).called(1);

      await tester.tap(find.byKey(const Key('debug_reset_all_data')));
      await tester.pumpAndSettle();
      verify(() => service.resetAllData()).called(1);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('other_debug_tools_item')), findsOneWidget);
      expect(find.byKey(const Key('other_debug_tools')), findsNothing);

      await tester.tap(find.byKey(const Key('other_debug_tools_item')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('debug_tools_password_field')),
        findsOneWidget,
      );
    },
  );
}
