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
        overrides: [
          splitsProvider.overrideWith((ref) => Stream.value(_sampleSplits)),
          recentHomeSessionsProvider.overrideWith((ref) async => const []),
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
  });

  testWidgets('splits add button opens split builder', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
