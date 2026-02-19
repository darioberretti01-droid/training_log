import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/splits/split_builder_screen.dart';
import 'package:training_log_app/features/splits/split_repository.dart';

void main() {
  testWidgets(
    'split builder shows validation when required fields are missing',
    (tester) async {
      final repository = _FakeSplitRepository();
      await _pumpSplitBuilder(tester, repository);

      await tester.tap(find.byKey(const Key('split_builder_save')));
      await tester.pumpAndSettle();

      expect(find.text('Split name is required.'), findsOneWidget);
      expect(repository.createCalls, 0);
    },
  );

  testWidgets('split builder saves a split and sets it active by default', (
    tester,
  ) async {
    final repository = _FakeSplitRepository();
    await _pumpSplitBuilder(tester, repository);

    await tester.enterText(
      find.byKey(const Key('split_name_field')),
      'Upper Lower',
    );
    await tester.enterText(find.byKey(const Key('day_1_title')), 'Upper A');

    await tester.tap(find.byKey(const Key('day_1_exercise_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('split_builder_save')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.setActiveCalls, 1);
    expect(repository.lastInput, isNotNull);
    expect(repository.lastInput!.name, 'Upper Lower');
    expect(repository.lastInput!.days, hasLength(1));
    expect(repository.lastInput!.days.first.dayIndex, 1);
    expect(repository.lastInput!.days.first.title, 'Upper A');
    expect(repository.lastInput!.days.first.plannedExercises, hasLength(1));
    expect(
      repository.lastInput!.days.first.plannedExercises.first.exerciseId,
      'bench_press',
    );
    expect(
      repository.lastInput!.days.first.plannedExercises.first.orderIndex,
      1,
    );
  });
}

Future<void> _pumpSplitBuilder(
  WidgetTester tester,
  _FakeSplitRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
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
        splitRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: SplitBuilderScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSplitRepository implements SplitRepository {
  int createCalls = 0;
  int setActiveCalls = 0;
  SplitDraftInput? lastInput;

  @override
  Future<String> createSplit(SplitDraftInput input) async {
    createCalls += 1;
    lastInput = input;
    return 'split_1';
  }

  @override
  Future<void> deleteSplit(String splitId) async {}

  @override
  Future<SplitDetails?> getSplitById(String splitId) async => null;

  @override
  Future<void> setActiveSplit(String splitId) async {
    setActiveCalls += 1;
  }

  @override
  Stream<List<SplitSummary>> watchSplits() {
    return Stream.value(const []);
  }
}
