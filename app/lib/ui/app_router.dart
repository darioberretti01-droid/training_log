import 'package:go_router/go_router.dart';

import '../features/exercises/exercise_history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/workouts/quick_workout_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
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
  ],
);
