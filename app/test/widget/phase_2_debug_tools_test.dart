import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/devtools/demo_fixture_models.dart';
import 'package:training_log_app/devtools/demo_fixture_service.dart';
import 'package:training_log_app/features/home/home_screen.dart';

class _MockDemoFixtureService extends Mock implements DemoFixtureService {}

void main() {
  setUpAll(() {
    registerFallbackValue(DemoFixtureScenario.baseRealistic);
  });

  testWidgets('debug tools are visible on Other tab in debug mode', (
    tester,
  ) async {
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
        child: const MaterialApp(home: Scaffold(body: OtherTabContent())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('other_debug_tools')), findsOneWidget);
    expect(find.byKey(const Key('debug_seed_demo_data')), findsOneWidget);
    expect(find.byKey(const Key('debug_reset_all_data')), findsOneWidget);
  });

  testWidgets('seed and reset debug actions call fixture service', (
    tester,
  ) async {
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
        child: const MaterialApp(home: Scaffold(body: OtherTabContent())),
      ),
    );
    await tester.pumpAndSettle();

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
  });
}
