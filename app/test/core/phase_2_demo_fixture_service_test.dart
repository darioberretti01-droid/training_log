import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/db/user_exercise_database.dart';
import 'package:training_log_app/devtools/demo_fixture_models.dart';
import 'package:training_log_app/devtools/demo_fixture_service.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';
import 'package:training_log_app/features/workouts/workout_draft_storage.dart';

void main() {
  late AppDatabase appDb;
  late UserExerciseDatabase userDb;
  late DriftExerciseRepository exerciseRepository;
  late DemoFixtureService fixtureService;

  setUp(() {
    appDb = AppDatabase(NativeDatabase.memory());
    userDb = UserExerciseDatabase(NativeDatabase.memory());
    exerciseRepository = DriftExerciseRepository(appDb, userDb);
    fixtureService = DemoFixtureService(
      appDb: appDb,
      userDb: userDb,
      exerciseRepository: exerciseRepository,
      workoutDraftStorage: WorkoutDraftStorage(appDb),
    );
  });

  tearDown(() async {
    await userDb.close();
    await appDb.close();
  });

  test('resetAllData clears both databases and draft table', () async {
    final now = DateTime(2026, 2, 23, 9, 30);
    await fixtureService.resetAndSeed(
      DemoFixtureScenario.homeKeepLoggingToday,
      now: now,
    );

    await fixtureService.resetAllData();

    expect(await _countRows(appDb, 'exercises'), 0);
    expect(await _countRows(appDb, 'splits'), 0);
    expect(await _countRows(appDb, 'workout_sessions'), 0);
    expect(await _countRows(appDb, 'workout_drafts'), 0);
    expect(await _countRows(userDb, 'user_exercises'), 0);
    expect(await _countRows(userDb, 'user_exercise_labels'), 0);
  });

  test('seedBaseFixture creates realistic split/session baseline', () async {
    await fixtureService.seedBaseFixture(now: DateTime(2026, 2, 23, 9, 30));

    expect(await _countRows(appDb, 'exercises'), greaterThan(0));
    expect(await _countRows(appDb, 'splits'), 3);
    expect(await _countRows(appDb, 'day_plans'), greaterThanOrEqualTo(7));
    expect(
      await _countRows(appDb, 'workout_sessions'),
      greaterThanOrEqualTo(4),
    );

    final activeSplits = await appDb
        .customSelect(
          'SELECT COUNT(*) AS cnt FROM splits WHERE is_active = 1',
          readsFrom: {appDb.splits},
        )
        .getSingle();
    expect(activeSplits.read<int>('cnt'), 1);
  });

  test('home overlays produce expected states', () async {
    final now = DateTime(2026, 2, 23, 9, 30);

    await fixtureService.resetAndSeed(
      DemoFixtureScenario.homeNoCurrentSplit,
      now: now,
    );
    expect(
      await appDb
          .customSelect(
            'SELECT COUNT(*) AS cnt FROM splits WHERE is_active = 1',
            readsFrom: {appDb.splits},
          )
          .map((row) => row.read<int>('cnt'))
          .getSingle(),
      0,
    );

    await fixtureService.resetAndSeed(
      DemoFixtureScenario.homeNoSessions,
      now: now,
    );
    expect(await _countRows(appDb, 'workout_sessions'), 0);
    expect(await _countRows(appDb, 'performed_sets'), 0);

    await fixtureService.resetAndSeed(
      DemoFixtureScenario.homeKeepLoggingToday,
      now: now,
    );
    expect(await _countRows(appDb, 'workout_drafts'), 1);
  });
}

Future<int> _countRows(GeneratedDatabase db, String tableName) async {
  final result = await db
      .customSelect('SELECT COUNT(*) AS cnt FROM $tableName')
      .getSingle();
  return result.read<int>('cnt');
}
