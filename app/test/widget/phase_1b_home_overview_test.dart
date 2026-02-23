import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/home/home_screen.dart';
import 'package:training_log_app/features/home/home_workout_logic.dart';
import 'package:training_log_app/features/splits/split_repository.dart';
import 'package:training_log_app/features/workouts/workout_draft.dart';
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

  testWidgets('tapping recent session opens session overview', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/home'),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeTabContent(),
        ),
        GoRoute(
          path: '/sessions/:sessionId',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return Scaffold(body: Text('Session target: $sessionId'));
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
          splitsProvider.overrideWith((ref) => Stream.value(const [])),
          recentHomeSessionsProvider.overrideWith((ref) async => sessions),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          lastSplitDaySessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_recent_session_session_nav')));
    await tester.pumpAndSettle();

    expect(find.text('Session target: session_nav'), findsOneWidget);
  });

  testWidgets(
    'next workout shows 3 recovery choices when last split exists but is not current',
    (tester) async {
      await _pumpHome(
        tester,
        recentSessionsLoader: (_) async => const [],
        splits: const [
          SplitSummary(
            id: 'split_current',
            name: 'Current Split',
            isActive: true,
            dayCount: 2,
            updatedAt: 1,
          ),
          SplitSummary(
            id: 'split_last',
            name: 'Last Used Split',
            isActive: false,
            dayCount: 3,
            updatedAt: 2,
          ),
        ],
        lastSplitDaySession: HomeSessionOverviewEntry(
          session: WorkoutSession(
            id: 'session_last_split',
            sessionType: WorkoutSessionMode.splitDay,
            splitId: 'split_last',
            dayIndex: 2,
            sessionName: 'Pull',
            startedAt: DateTime(2026, 1, 15, 8, 0).millisecondsSinceEpoch,
            endedAt: DateTime(2026, 1, 15, 8, 45).millisecondsSinceEpoch,
          ),
          exercises: const [],
          totalSets: 8,
          splitId: 'split_last',
          dayIndex: 2,
          sessionName: 'Pull',
        ),
      );

      expect(find.text('Set last used split as current'), findsOneWidget);
      expect(find.text('Log new current split'), findsOneWidget);
      expect(find.byKey(const Key('home_create_split')), findsOneWidget);
      expect(find.text('Create new split'), findsOneWidget);
    },
  );

  testWidgets(
    'next workout shows 2 recovery choices when last split was deleted',
    (tester) async {
      await _pumpHome(
        tester,
        recentSessionsLoader: (_) async => const [],
        splits: const [
          SplitSummary(
            id: 'split_current',
            name: 'Current Split',
            isActive: true,
            dayCount: 2,
            updatedAt: 1,
          ),
        ],
        lastSplitDaySession: HomeSessionOverviewEntry(
          session: WorkoutSession(
            id: 'session_deleted_split',
            sessionType: WorkoutSessionMode.splitDay,
            splitId: 'split_deleted',
            dayIndex: 1,
            sessionName: 'Upper',
            startedAt: DateTime(2026, 1, 16, 8, 0).millisecondsSinceEpoch,
            endedAt: DateTime(2026, 1, 16, 8, 40).millisecondsSinceEpoch,
          ),
          exercises: const [],
          totalSets: 7,
          splitId: 'split_deleted',
          dayIndex: 1,
          sessionName: 'Upper',
        ),
      );

      expect(find.text('Set last used split as current'), findsNothing);
      expect(find.text('Log new current split'), findsOneWidget);
      expect(find.byKey(const Key('home_create_split')), findsOneWidget);
      expect(find.text('Create new split'), findsOneWidget);
    },
  );

  testWidgets(
    'next workout shows Log current split when current split exists',
    (tester) async {
      await _pumpHome(
        tester,
        recentSessionsLoader: (_) async => const [],
        splits: const [
          SplitSummary(
            id: 'split_current',
            name: 'Current Split',
            isActive: true,
            dayCount: 2,
            updatedAt: 1,
          ),
        ],
        suggestedWorkout: const SuggestedWorkoutCardState(
          splitId: 'split_current',
          splitName: 'Current Split',
          nextDayName: 'Upper',
          nextDayIndex: 1,
          exerciseCount: 4,
          estimatedDurationMinutes: 30,
          previewExerciseNames: ['Bench Press'],
          lastSessionSummary: null,
        ),
      );

      expect(find.text('Log current split'), findsOneWidget);
    },
  );

  testWidgets('next workout shows Set current split when no current split', (
    tester,
  ) async {
    await _pumpHome(tester, recentSessionsLoader: (_) async => const []);

    expect(find.text('Set current split'), findsOneWidget);
  });

  testWidgets(
    'recovery shows Set current split when there is no active split',
    (tester) async {
      await _pumpHome(
        tester,
        recentSessionsLoader: (_) async => const [],
        splits: const [
          SplitSummary(
            id: 'split_a',
            name: 'Split A',
            isActive: false,
            dayCount: 2,
            updatedAt: 1,
          ),
        ],
        lastSplitDaySession: HomeSessionOverviewEntry(
          session: WorkoutSession(
            id: 'session_deleted_split_no_active',
            sessionType: WorkoutSessionMode.splitDay,
            splitId: 'split_deleted',
            dayIndex: 1,
            sessionName: 'Upper',
            startedAt: DateTime(2026, 1, 17, 8, 0).millisecondsSinceEpoch,
            endedAt: DateTime(2026, 1, 17, 8, 40).millisecondsSinceEpoch,
          ),
          exercises: const [],
          totalSets: 7,
          splitId: 'split_deleted',
          dayIndex: 1,
          sessionName: 'Upper',
        ),
      );

      expect(find.text('Set current split'), findsOneWidget);
      expect(find.text('Log new current split'), findsNothing);
    },
  );

  testWidgets('home secondary actions include log different day', (
    tester,
  ) async {
    await _pumpHome(tester, recentSessionsLoader: (_) async => const []);

    expect(find.text('Log different split'), findsOneWidget);
    expect(find.text('Log different day'), findsOneWidget);
    expect(find.text('Free workout'), findsOneWidget);
    expect(find.text('Create new split'), findsOneWidget);
    expect(find.text('Log single exercise'), findsNothing);
  });

  testWidgets('home shows keep logging action for today draft', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _pumpHome(
      tester,
      recentSessionsLoader: (_) async => const [],
      workoutDraft: WorkoutDraft(
        mode: WorkoutSessionMode.free,
        startedAtMs: now,
        updatedAtMs: now,
        exercises: const [
          WorkoutDraftExercise(
            exerciseId: 'bench_press',
            exerciseName: 'Bench Press',
            labels: ['push'],
            repMin: 8,
            repMax: 12,
            targetSets: 1,
            rows: [],
          ),
        ],
      ),
    );

    expect(find.text("Keep logging today's workout"), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Future<List<HomeSessionOverviewEntry>> Function(Ref ref)
  recentSessionsLoader,
  List<SplitSummary> splits = const [],
  HomeSessionOverviewEntry? lastSplitDaySession,
  SuggestedWorkoutCardState? suggestedWorkout,
  WorkoutDraft? workoutDraft,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeTabContent(),
      ),
      GoRoute(
        path: '/sessions/:sessionId',
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
        splitsProvider.overrideWith((ref) => Stream.value(splits)),
        recentHomeSessionsProvider.overrideWith(recentSessionsLoader),
        lastHomeSessionProvider.overrideWith((ref) async => null),
        lastSplitDaySessionProvider.overrideWith(
          (ref) async => lastSplitDaySession,
        ),
        suggestedWorkoutCardStateProvider.overrideWith(
          (ref) async => suggestedWorkout,
        ),
        todayWorkoutDraftProvider.overrideWith((ref) => workoutDraft),
        activeSplitDetailsProvider.overrideWith((ref) async => null),
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
