import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/exercises/exercise_list_screen.dart';

void main() {
  testWidgets('shows search and add controls without history icon button', (
    tester,
  ) async {
    await _pumpExerciseList(
      tester,
      exercises: const [
        ExerciseWithLabels(
          id: 'bench_press',
          name: 'Barbell Bench Press',
          labels: ['chest', 'push'],
        ),
      ],
    );

    expect(find.byKey(const Key('exercises_search_field')), findsOneWidget);
    expect(find.byKey(const Key('exercises_add_button')), findsOneWidget);
    expect(find.byIcon(Icons.history), findsNothing);
  });

  testWidgets('division dropdown can switch to all exercises', (tester) async {
    await _pumpExerciseList(
      tester,
      exercises: const [
        ExerciseWithLabels(
          id: 'bench_press',
          name: 'Barbell Bench Press',
          labels: ['chest', 'push'],
        ),
        ExerciseWithLabels(
          id: 'custom_mobility',
          name: 'Ankle Mobility',
          labels: ['mobility'],
          isStandard: false,
        ),
      ],
    );

    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercises_grouping_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All exercises').last);
    await tester.pumpAndSettle();

    expect(find.text('All exercises'), findsWidgets);
    expect(find.text('Chest'), findsNothing);
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('most-used ordering can be inverted in list mode', (tester) async {
    await _pumpExerciseList(
      tester,
      exercises: const [
        ExerciseWithLabels(id: 'alpha', name: 'Alpha Press', labels: ['chest']),
        ExerciseWithLabels(id: 'beta', name: 'Beta Press', labels: ['chest']),
      ],
      logCountMap: const {
        'alpha': 6,
        'beta': 1,
      },
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('exercises_view_toggle')),
        matching: find.byIcon(Icons.view_list_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercises_order_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Most used').last);
    await tester.pumpAndSettle();

    final alphaBefore =
        tester.getTopLeft(find.byKey(const Key('exercise_list_alpha'))).dy;
    final betaBefore =
        tester.getTopLeft(find.byKey(const Key('exercise_list_beta'))).dy;
    expect(alphaBefore, lessThan(betaBefore));

    await tester.tap(find.byKey(const Key('exercises_order_invert_button')));
    await tester.pumpAndSettle();

    final alphaAfter =
        tester.getTopLeft(find.byKey(const Key('exercise_list_alpha'))).dy;
    final betaAfter =
        tester.getTopLeft(find.byKey(const Key('exercise_list_beta'))).dy;
    expect(alphaAfter, greaterThan(betaAfter));
  });

  testWidgets('hidden toggle shows hidden exercises only', (tester) async {
    await _pumpExerciseList(
      tester,
      exercises: const [
        ExerciseWithLabels(
          id: 'bench_press',
          name: 'Barbell Bench Press',
          labels: ['chest', 'push'],
          isStandard: true,
        ),
        ExerciseWithLabels(
          id: 'pull_up',
          name: 'Pull-Up',
          labels: ['back', 'pull'],
          isStandard: true,
          isHidden: true,
        ),
      ],
    );

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pull-Up'), findsNothing);

    await tester.tap(find.byKey(const Key('exercises_toggle_hidden_button')));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsNothing);
    expect(find.text('Pull-Up'), findsOneWidget);
  });

  testWidgets('delete mode shows hide/delete trailing actions', (tester) async {
    await _pumpExerciseList(
      tester,
      exercises: const [
        ExerciseWithLabels(
          id: 'bench_press',
          name: 'Barbell Bench Press',
          labels: ['chest', 'push'],
          isStandard: true,
        ),
        ExerciseWithLabels(
          id: 'custom_mobility',
          name: 'Ankle Mobility',
          labels: ['mobility'],
          isStandard: false,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('exercises_delete_mode_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exercise_hide_bench_press')), findsOneWidget);
    expect(
      find.byKey(const Key('exercise_delete_custom_mobility')),
      findsOneWidget,
    );
  });

  testWidgets('narrow layout does not overflow controls', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpExerciseList(
      tester,
      exercises: const [
        ExerciseWithLabels(
          id: 'bench_press',
          name: 'Barbell Bench Press',
          labels: ['chest', 'push', 'compound'],
        ),
        ExerciseWithLabels(
          id: 'front_squat',
          name: 'Front Squat',
          labels: ['legs', 'quads', 'compound'],
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('exercises_search_field')), findsOneWidget);
    final divisionCenter = tester.getCenter(
      find.byKey(const Key('exercises_grouping_dropdown')),
    );
    final addCenter = tester.getCenter(find.byKey(const Key('exercises_add_button')));
    expect((divisionCenter.dy - addCenter.dy).abs(), lessThan(6));
    expect(addCenter.dx, greaterThan(divisionCenter.dx));
    expect(find.byKey(const Key('exercises_order_dropdown')), findsOneWidget);
    expect(find.byKey(const Key('exercises_toggle_hidden_button')), findsOneWidget);
  });
}

Future<void> _pumpExerciseList(
  WidgetTester tester, {
  required List<ExerciseWithLabels> exercises,
  Map<String, int> createdAtMap = const {},
  Map<String, int> logCountMap = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seedDataProvider.overrideWith((ref) async {}),
        exercisesProvider.overrideWith((ref) => Stream.value(exercises)),
        exerciseCreatedAtMapProvider.overrideWith(
          (ref) => Stream.value(createdAtMap),
        ),
        exerciseLogCountMapProvider.overrideWith(
          (ref) => Stream.value(logCountMap),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ExerciseListContent()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
