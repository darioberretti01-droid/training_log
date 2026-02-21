import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/exercises/exercise_create_screen.dart';
import '../features/exercises/exercise_history_screen.dart';
import '../features/exercises/exercise_labels_screen.dart';
import '../features/exercises/exercise_list_screen.dart';
import '../features/exercises/labels_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splits/split_builder_screen.dart';
import '../features/splits/split_detail_screen.dart';
import '../features/splits/splits_screen.dart';
import '../features/workouts/quick_workout_screen.dart';
import 'root_shell.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    ShellRoute(
      builder: (context, state, child) {
        return RootShell(state: state, child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeTabContent()),
        GoRoute(
          path: '/splits',
          builder: (context, state) => const SplitsScreen(),
          routes: [
            GoRoute(
              path: 'builder',
              builder: (context, state) => const SplitBuilderScreen(),
            ),
            GoRoute(
              path: ':splitId',
              builder: (context, state) {
                final splitId = state.pathParameters['splitId']!;
                return SplitDetailScreen(splitId: splitId);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final splitId = state.pathParameters['splitId']!;
                    return SplitBuilderScreen(editingSplitId: splitId);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/exercises',
          builder: (context, state) => const ExerciseListContent(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const ExerciseCreateScreen(),
            ),
            GoRoute(
              path: ':exerciseId/history',
              builder: (context, state) {
                final exerciseId = state.pathParameters['exerciseId']!;
                return ExerciseHistoryScreen(exerciseId: exerciseId);
              },
            ),
            GoRoute(
              path: ':exerciseId/labels',
              builder: (context, state) {
                final exerciseId = state.pathParameters['exerciseId']!;
                return ExerciseLabelsScreen(exerciseId: exerciseId);
              },
            ),
            GoRoute(
              path: ':exerciseId/quick',
              builder: (context, state) {
                final exerciseId = state.pathParameters['exerciseId']!;
                return QuickWorkoutScreen(exerciseId: exerciseId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/other',
          builder: (context, state) => const OtherTabContent(),
          routes: [
            GoRoute(
              path: 'labels',
              builder: (context, state) => const LabelsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  navigatorKey: _rootNavigatorKey,
);

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
