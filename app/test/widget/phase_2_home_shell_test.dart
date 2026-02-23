import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/app.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/splits/split_repository.dart';

void main() {
  testWidgets('splits tab shows active split and all splits list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith((ref) => Stream.value(const [])),
          splitsProvider.overrideWith((ref) => Stream.value(_sampleSplits)),
          recentHomeSessionsProvider.overrideWith((ref) async => const []),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          lastSplitDaySessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
          activeSplitProvider.overrideWith(
            (ref) => const AsyncValue.data(null),
          ),
        ],
        child: const TrainingLogApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.view_week_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Current split'), findsOneWidget);
    expect(find.text('All splits'), findsOneWidget);
    expect(find.text('Upper Lower'), findsNWidgets(2));
    expect(find.text('Push Pull Legs'), findsOneWidget);
    expect(find.byKey(const Key('splits_add_button')), findsOneWidget);
    expect(find.text('ADD SPLIT'), findsOneWidget);
  });

  testWidgets('splits add button opens split builder', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          splitsProvider.overrideWith((ref) => Stream.value(_sampleSplits)),
          recentHomeSessionsProvider.overrideWith((ref) async => const []),
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(const [
              ExerciseWithLabels(
                id: 'bench_press',
                name: 'Barbell Bench Press',
                labels: ['push', 'chest'],
              ),
            ]),
          ),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          lastSplitDaySessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
          activeSplitProvider.overrideWith(
            (ref) => const AsyncValue.data(null),
          ),
        ],
        child: const TrainingLogApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.view_week_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('splits_add_button')));
    await tester.pumpAndSettle();

    expect(find.text('Split Builder'), findsOneWidget);
  });

  testWidgets('back from splits root returns to home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith((ref) => Stream.value(const [])),
          splitsProvider.overrideWith((ref) => Stream.value(_sampleSplits)),
          recentHomeSessionsProvider.overrideWith((ref) async => const []),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          lastSplitDaySessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
          activeSplitProvider.overrideWith(
            (ref) => const AsyncValue.data(null),
          ),
        ],
        child: const TrainingLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_week_outlined));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Splits')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Home')),
      findsOneWidget,
    );
  });

  testWidgets('back from other root returns to home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith((ref) => Stream.value(const [])),
          splitsProvider.overrideWith((ref) => Stream.value(_sampleSplits)),
          recentHomeSessionsProvider.overrideWith((ref) async => const []),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          lastSplitDaySessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
          activeSplitProvider.overrideWith(
            (ref) => const AsyncValue.data(null),
          ),
        ],
        child: const TrainingLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Other')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Home')),
      findsOneWidget,
    );
  });

  testWidgets('tapping split opens split details screen', (tester) async {
    final repository = _FakeSplitRepository()
      ..detailsById['split_1'] = const SplitDetails(
        id: 'split_1',
        name: 'Upper Lower',
        isActive: true,
        createdAt: 1,
        updatedAt: 2,
        days: [
          DayPlanDetails(
            id: 'day_1',
            dayIndex: 1,
            title: 'Upper A',
            plannedExercises: [
              PlannedExerciseDetails(
                id: 'plan_1',
                orderIndex: 1,
                exerciseId: 'bench_press',
                exerciseName: 'Barbell Bench Press',
                targetSets: 3,
                repMin: 8,
                repMax: 12,
                restSeconds: null,
                targetRpe: null,
              ),
            ],
          ),
        ],
      );
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith((ref) => Stream.value(const [])),
          splitsProvider.overrideWith((ref) => Stream.value(_sampleSplits)),
          splitRepositoryProvider.overrideWithValue(repository),
          recentHomeSessionsProvider.overrideWith((ref) async => const []),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          lastSplitDaySessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
          activeSplitProvider.overrideWith(
            (ref) => const AsyncValue.data(null),
          ),
        ],
        child: const TrainingLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_week_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upper Lower').first);
    await tester.pumpAndSettle();

    expect(find.text('Days'), findsOneWidget);
    expect(find.byKey(const Key('split_detail_edit')), findsOneWidget);
    expect(find.byKey(const Key('split_detail_delete')), findsOneWidget);
    expect(
      find.byKey(const Key('split_detail_volume_overview')),
      findsOneWidget,
    );
  });
}

final _sampleSplits = [
  SplitSummary(
    id: 'split_1',
    name: 'Upper Lower',
    isActive: true,
    dayCount: 2,
    updatedAt: 1,
  ),
  SplitSummary(
    id: 'split_2',
    name: 'Push Pull Legs',
    isActive: false,
    dayCount: 3,
    updatedAt: 2,
  ),
];

class _FakeSplitRepository implements SplitRepository {
  final Map<String, SplitDetails> detailsById = {};

  @override
  Future<String> createSplit(SplitDraftInput input) async => 'split_new';

  @override
  Future<void> deleteSplit(String splitId) async {}

  @override
  Future<SplitDetails?> getSplitById(String splitId) async =>
      detailsById[splitId];

  @override
  Future<void> setActiveSplit(String splitId) async {}

  @override
  Future<void> updateSplit(String splitId, SplitDraftInput input) async {}

  @override
  Stream<List<SplitSummary>> watchSplits() => Stream.value(_sampleSplits);
}
