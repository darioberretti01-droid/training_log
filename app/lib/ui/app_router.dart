import 'package:go_router/go_router.dart';

import '../features/exercises/exercise_create_screen.dart';
import '../features/exercises/exercise_history_screen.dart';
import '../features/exercises/exercise_labels_screen.dart';
import '../features/exercises/labels_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splits/split_builder_screen.dart';
import '../features/workouts/quick_workout_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/quick/:exerciseId',
      builder: (context, state) {
        final exerciseId = state.pathParameters['exerciseId']!;
        return QuickWorkoutScreen(exerciseId: exerciseId);
      },
    ),
    GoRoute(
      path: '/history/:exerciseId',
      builder: (context, state) {
        final exerciseId = state.pathParameters['exerciseId']!;
        return ExerciseHistoryScreen(exerciseId: exerciseId);
      },
    ),
    GoRoute(
      path: '/exercises/new',
      builder: (context, state) => const ExerciseCreateScreen(),
    ),
    GoRoute(
      path: '/exercises/:exerciseId/labels',
      builder: (context, state) {
        final exerciseId = state.pathParameters['exerciseId']!;
        return ExerciseLabelsScreen(exerciseId: exerciseId);
      },
    ),
    GoRoute(path: '/labels', builder: (context, state) => const LabelsScreen()),
    GoRoute(
      path: '/splits/builder',
      builder: (context, state) => const SplitBuilderScreen(),
    ),
  ],
);
