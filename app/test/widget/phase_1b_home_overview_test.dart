import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/home/home_screen.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';

void main() {
  testWidgets('home shows recent sessions below home actions', (tester) async {
    final sessions = [
      _entry(
        sessionId: 'session_1',
        startedAt: DateTime(2026, 1, 10, 7, 0),
        endedAt: DateTime(2026, 1, 10, 7, 45),
        totalSets: 5,
        exercises: const [
          HomeSessionExerciseSummary(
            exerciseId: 'bench_press',
            exerciseName: 'Bench Press',
            setCount: 3,
          ),
          HomeSessionExerciseSummary(
            exerciseId: 'barbell_row',
            exerciseName: 'Barbell Row',
            setCount: 1,
          ),
          HomeSessionExerciseSummary(
            exerciseId: 'back_squat',
            exerciseName: 'Back Squat',
            setCount: 1,
          ),
        ],
      ),
    ];

    await _pumpHome(tester, recentSessionsLoader: (_) async => sessions);

    expect(find.text('Recent sessions'), findsOneWidget);
    expect(find.text('Quick workout - Jan 10'), findsOneWidget);
    expect(find.text('5 sets'), findsOneWidget);
    expect(find.byKey(const Key('home_log_current_split')), findsOneWidget);
  });

  testWidgets('home recent sessions shows empty state', (tester) async {
    await _pumpHome(tester, recentSessionsLoader: (_) async => const []);

    expect(find.text('No sessions logged yet.'), findsOneWidget);
    expect(find.byKey(const Key('home_log_current_split')), findsOneWidget);
  });

  testWidgets('home recent sessions shows error state and retry reloads', (
    tester,
  ) async {
    var attempts = 0;

    await _pumpHome(
      tester,
      recentSessionsLoader: (_) async {
        attempts += 1;
        throw Exception('boom');
      },
    );

    expect(
      find.textContaining('Failed to load recent sessions:'),
      findsOneWidget,
    );

    final attemptsBeforeRetry = attempts;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Failed to load recent sessions:'),
      findsOneWidget,
    );
    expect(attempts, greaterThan(attemptsBeforeRetry));
  });

  testWidgets('tapping recent session opens history for primary exercise', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/home'),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeTabContent(),
        ),
        GoRoute(
          path: '/exercises/:exerciseId/history',
          builder: (context, state) {
            final exerciseId = state.pathParameters['exerciseId']!;
            return Scaffold(body: Text('History target: $exerciseId'));
          },
        ),
      ],
    );

    final sessions = [
      _entry(
        sessionId: 'session_nav',
        startedAt: DateTime(2026, 1, 12, 7, 0),
        endedAt: DateTime(2026, 1, 12, 7, 30),
        totalSets: 3,
        exercises: const [
          HomeSessionExerciseSummary(
            exerciseId: 'bench_press',
            exerciseName: 'Bench Press',
            setCount: 2,
          ),
          HomeSessionExerciseSummary(
            exerciseId: 'barbell_row',
            exerciseName: 'Barbell Row',
            setCount: 1,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(_defaultExercises),
          ),
          recentHomeSessionsProvider.overrideWith((ref) async => sessions),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
          activeSplitProvider.overrideWith(
            (ref) => const AsyncValue.data(null),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_recent_session_session_nav')));
    await tester.pumpAndSettle();

    expect(find.text('History target: bench_press'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Future<List<HomeSessionOverviewEntry>> Function(Ref ref)
  recentSessionsLoader,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeTabContent(),
      ),
      GoRoute(
        path: '/exercises/:exerciseId/history',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      retry: (count, error) => null,
      overrides: [
        seedDataProvider.overrideWith((ref) async {}),
        exercisesProvider.overrideWith(
          (ref) => Stream.value(_defaultExercises),
        ),
        recentHomeSessionsProvider.overrideWith(recentSessionsLoader),
        lastHomeSessionProvider.overrideWith((ref) async => null),
        suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
        activeSplitDetailsProvider.overrideWith((ref) async => null),
        activeSplitProvider.overrideWith((ref) => const AsyncValue.data(null)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

final _defaultExercises = [
  const ExerciseWithLabels(
    id: 'bench_press',
    name: 'Barbell Bench Press',
    labels: ['push'],
  ),
];

HomeSessionOverviewEntry _entry({
  required String sessionId,
  required DateTime startedAt,
  required DateTime endedAt,
  required int totalSets,
  required List<HomeSessionExerciseSummary> exercises,
}) {
  return HomeSessionOverviewEntry(
    session: WorkoutSession(
      id: sessionId,
      sessionType: 'quick',
      startedAt: startedAt.millisecondsSinceEpoch,
      endedAt: endedAt.millisecondsSinceEpoch,
    ),
    exercises: exercises,
    totalSets: totalSets,
  );
}
