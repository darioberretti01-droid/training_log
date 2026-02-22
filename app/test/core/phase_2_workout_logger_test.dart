import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/db/user_exercise_database.dart';
import 'package:training_log_app/core/models/logged_set_input.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';
import 'package:training_log_app/features/home/home_workout_logic.dart';
import 'package:training_log_app/features/splits/split_repository.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';

void main() {
  late AppDatabase database;
  late UserExerciseDatabase userExerciseDatabase;
  late DriftExerciseRepository exerciseRepository;
  late DriftSplitRepository splitRepository;
  late DriftQuickWorkoutRepository workoutRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    userExerciseDatabase = UserExerciseDatabase(NativeDatabase.memory());
    exerciseRepository = DriftExerciseRepository(
      database,
      userExerciseDatabase,
    );
    splitRepository = DriftSplitRepository(database);
    workoutRepository = DriftQuickWorkoutRepository(database);
  });

  tearDown(() async {
    await userExerciseDatabase.close();
    await database.close();
  });

  test('getNextDayIndexSequence advances and wraps in sequence mode', () {
    const split = SplitDetails(
      id: 'split_1',
      name: 'Upper Lower',
      isActive: true,
      createdAt: 1,
      updatedAt: 2,
      days: [
        DayPlanDetails(
          id: 'd1',
          dayIndex: 1,
          title: 'Upper',
          plannedExercises: [],
        ),
        DayPlanDetails(
          id: 'd2',
          dayIndex: 2,
          title: 'Lower',
          plannedExercises: [],
        ),
      ],
    );

    const session = HomeSessionOverviewEntry(
      session: WorkoutSession(
        id: 's1',
        sessionType: WorkoutSessionMode.splitDay,
        splitId: 'split_1',
        dayIndex: 2,
        sessionName: 'Lower',
        startedAt: 100,
        endedAt: 200,
      ),
      exercises: [],
      totalSets: 6,
      splitId: 'split_1',
      dayIndex: 2,
      sessionName: 'Lower',
    );

    final wrapped = getNextDayIndexSequence(split, session);
    final first = getNextDayIndexSequence(split, null);

    expect(wrapped, 1);
    expect(first, 1);
  });

  test('saveWorkoutSession persists free workout session and sets', () async {
    await exerciseRepository.seedIfEmpty();
    final exercises = await exerciseRepository.watchExercises().first;

    final sessionId = await workoutRepository.saveWorkoutSession(
      mode: WorkoutSessionMode.free,
      sessionName: 'Free workout',
      startedAt: DateTime(2026, 2, 22, 9, 0),
      endedAt: DateTime(2026, 2, 22, 9, 40),
      exercises: [
        WorkoutExerciseLogInput(
          exerciseId: exercises[0].id,
          sets: const [
            LoggedSetInput(reps: 10, weightKg: 50),
            LoggedSetInput(reps: 8, weightKg: 52.5, restSeconds: 90),
          ],
        ),
        WorkoutExerciseLogInput(
          exerciseId: exercises[1].id,
          sets: const [LoggedSetInput(reps: 12, weightKg: 20)],
        ),
      ],
    );

    final session = await (database.select(
      database.workoutSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).getSingle();
    final sets = await (database.select(
      database.performedSets,
    )..where((tbl) => tbl.sessionId.equals(sessionId))).get();

    expect(session.sessionType, WorkoutSessionMode.free);
    expect(session.sessionName, 'Free workout');
    expect(session.splitId, isNull);
    expect(session.dayIndex, isNull);
    expect(sets, hasLength(3));
  });

  test('saveWorkoutSession persists split-day metadata', () async {
    await exerciseRepository.seedIfEmpty();
    final exercises = await exerciseRepository.watchExercises().first;
    final splitId = await splitRepository.createSplit(
      SplitDraftInput(
        name: 'Upper Lower',
        days: [
          DayPlanDraftInput(
            dayIndex: 1,
            title: 'Upper',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[0].id,
                targetSets: 3,
                repMin: 6,
                repMax: 10,
              ),
            ],
          ),
        ],
      ),
    );

    final sessionId = await workoutRepository.saveWorkoutSession(
      mode: WorkoutSessionMode.splitDay,
      splitId: splitId,
      dayIndex: 1,
      sessionName: 'Upper',
      startedAt: DateTime(2026, 2, 22, 10, 0),
      endedAt: DateTime(2026, 2, 22, 10, 25),
      exercises: [
        WorkoutExerciseLogInput(
          exerciseId: exercises[0].id,
          sets: const [
            LoggedSetInput(reps: 8, weightKg: 60, restSeconds: 120, rpe: 8),
          ],
        ),
      ],
    );

    final session = await (database.select(
      database.workoutSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).getSingle();

    expect(session.sessionType, WorkoutSessionMode.splitDay);
    expect(session.splitId, splitId);
    expect(session.dayIndex, 1);
    expect(session.sessionName, 'Upper');
  });
}
