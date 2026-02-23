import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:training_log_app/app.dart';
import 'package:training_log_app/core/state/providers.dart';

import 'screenshots_manifest.dart';

final _fixedNow = DateTime(2026, 2, 23, 9, 30);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
  });

  tearDownAll(() async {});

  for (final entry in screenshotManifest) {
    testWidgets(
      'screenshot ${entry.order.toString().padLeft(2, '0')} - ${entry.id}',
      (tester) async {
        tester.binding.platformDispatcher.localeTestValue = const Locale(
          'en',
          'US',
        );
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;
        tester.binding.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;

        final container = ProviderContainer(
          overrides: [appClockProvider.overrideWithValue(() => _fixedNow)],
        );
        addTearDown(() {
          tester.binding.platformDispatcher.clearLocaleTestValue();
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
          tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
          container.dispose();
        });

        await container
            .read(demoFixtureServiceProvider)
            .resetAndSeed(entry.scenario, now: _fixedNow);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const TrainingLogApp(),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await _runCaptureStep(tester, entry.captureStep);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));
        await binding.takeScreenshot(entry.id);
      },
    );
  }
}

Future<void> _runCaptureStep(
  WidgetTester tester,
  ScreenshotCaptureStep step,
) async {
  switch (step) {
    case ScreenshotCaptureStep.homeDefault:
      await _goHome(tester);
      return;
    case ScreenshotCaptureStep.homeKeepLoggingToday:
      await _goHome(tester);
      await tester.ensureVisible(
        find.byKey(const Key('home_keep_logging_today')),
      );
      return;
    case ScreenshotCaptureStep.homeSetCurrentSplit:
      await _goHome(tester);
      await tester.ensureVisible(find.text('Set current split'));
      return;
    case ScreenshotCaptureStep.homeRecoveryLastUsedExists:
      await _goHome(tester);
      await tester.ensureVisible(find.text('Set last used split as current'));
      return;
    case ScreenshotCaptureStep.homeRecoveryLastUsedDeleted:
      await _goHome(tester);
      await tester.ensureVisible(
        find.text('Your last used split was deleted.'),
      );
      return;
    case ScreenshotCaptureStep.homeRecentSessionsPopulated:
      await _goHome(tester);
      await tester.ensureVisible(find.text('Recent sessions'));
      return;
    case ScreenshotCaptureStep.homeRecentSessionsEmpty:
      await _goHome(tester);
      await tester.ensureVisible(find.text('No sessions logged yet.'));
      return;
    case ScreenshotCaptureStep.splitsList:
      await _goToSplitsTab(tester);
      return;
    case ScreenshotCaptureStep.splitDetail:
      await _goToSplitsTab(tester);
      await tester.tap(find.text('Upper / Lower').first);
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.splitBuilder:
      await _goToSplitsTab(tester);
      await tester.tap(find.byKey(const Key('splits_add_button')));
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.exercisesList:
      await _goToExercisesTab(tester);
      return;
    case ScreenshotCaptureStep.exerciseHistory:
      await _goToExercisesTab(tester);
      await _openExerciseHistory(tester);
      return;
    case ScreenshotCaptureStep.exerciseLabelsEditor:
      await _goToExercisesTab(tester);
      await _openExerciseHistory(tester);
      await tester.ensureVisible(
        find.byKey(const Key('exercise_history_edit_labels')),
      );
      await tester.tap(find.byKey(const Key('exercise_history_edit_labels')));
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.labelsCatalog:
      await _goToOtherTab(tester);
      await tester.tap(find.byKey(const Key('other_labels_item')));
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.loggerSplitDayInitial:
      await _goHome(tester);
      await tester.tap(find.byKey(const Key('home_log_current_split')));
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.loggerSplitDayWithInputs:
      await _goHome(tester);
      await tester.tap(find.byKey(const Key('home_log_current_split')));
      await tester.pumpAndSettle();
      await _enterFirstSet(tester);
      return;
    case ScreenshotCaptureStep.loggerFreeEmpty:
      await _goHome(tester);
      await tester.tap(find.byKey(const Key('home_free_workout')));
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.loggerFreeWithExercises:
      await _goHome(tester);
      await tester.tap(find.byKey(const Key('home_free_workout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workout_logger_add_exercise')));
      await tester.pumpAndSettle();
      if (find.text('Back Squat').evaluate().isNotEmpty) {
        await tester.tap(find.text('Back Squat').first);
      } else {
        await tester.tap(find.byType(ListTile).first);
      }
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.loggerFinishUnfilledWarning:
      await _goHome(tester);
      await tester.tap(find.byKey(const Key('home_log_current_split')));
      await tester.pumpAndSettle();
      await _enterFirstSet(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
      await tester.pumpAndSettle();
      return;
    case ScreenshotCaptureStep.sessionOverviewEditable:
      await _goHome(tester);
      final recentSessionFinder = find.byWidgetPredicate((widget) {
        if (widget is ListTile && widget.key is Key) {
          final key = widget.key!;
          return key.toString().contains('home_recent_session_');
        }
        return false;
      });
      if (recentSessionFinder.evaluate().isNotEmpty) {
        await tester.tap(recentSessionFinder.first);
        await tester.pumpAndSettle();
      }
      return;
  }
}

Future<void> _goHome(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.home_outlined));
  await tester.pumpAndSettle();
}

Future<void> _goToSplitsTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.view_week_outlined));
  await tester.pumpAndSettle();
}

Future<void> _goToExercisesTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.fitness_center_outlined));
  await tester.pumpAndSettle();
}

Future<void> _goToOtherTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_horiz));
  await tester.pumpAndSettle();
}

Future<void> _openExerciseHistory(WidgetTester tester) async {
  final candidates = <Finder>[
    find.byKey(const Key('exercise_pill_back_squat')),
    find.byKey(const Key('exercise_list_back_squat')),
    find.byWidgetPredicate((widget) {
      final key = widget.key;
      if (key == null) {
        return false;
      }
      final value = key.toString();
      return value.contains('exercise_pill_') ||
          value.contains('exercise_list_');
    }),
    find.text('Back Squat'),
  ];

  for (final finder in candidates) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
      return;
    }
  }

  throw StateError('Could not find any exercise item to open history.');
}

Future<void> _enterFirstSet(WidgetTester tester) async {
  final fields = find.byType(TextField);
  if (fields.evaluate().length < 2) {
    return;
  }
  await tester.enterText(fields.at(0), '82.5');
  await tester.enterText(fields.at(1), '8');
  await tester.pumpAndSettle();
}
