import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/db/user_exercise_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';
import 'package:training_log_app/features/splits/split_repository.dart';

void main() {
  late AppDatabase database;
  late UserExerciseDatabase userExerciseDatabase;
  late DriftExerciseRepository exerciseRepository;
  late DriftSplitRepository splitRepository;
  late int nowMs;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    userExerciseDatabase = UserExerciseDatabase(NativeDatabase.memory());
    exerciseRepository = DriftExerciseRepository(database, userExerciseDatabase);
    nowMs = DateTime(2026, 2, 20, 9, 0).millisecondsSinceEpoch;
    splitRepository = DriftSplitRepository(
      database,
      now: () => DateTime.fromMillisecondsSinceEpoch(nowMs),
    );
  });

  tearDown(() async {
    await userExerciseDatabase.close();
    await database.close();
  });

  test('createSplit persists split/day/planned rows transactionally', () async {
    final exercises = await _seedExercises(exerciseRepository);

    final splitId = await splitRepository.createSplit(
      SplitDraftInput(
        name: 'Upper Lower',
        days: [
          DayPlanDraftInput(
            dayIndex: 1,
            title: 'Upper A',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[0].id,
                targetSets: 3,
                repMin: 6,
                repMax: 10,
                restSeconds: 120,
                targetRpe: 8.0,
              ),
              PlannedExerciseDraftInput(
                orderIndex: 2,
                exerciseId: exercises[1].id,
                targetSets: 3,
                repMin: 8,
                repMax: 12,
              ),
            ],
          ),
          DayPlanDraftInput(
            dayIndex: 2,
            title: 'Lower A',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[2].id,
                targetSets: 4,
                repMin: 5,
                repMax: 8,
                restSeconds: 180,
              ),
            ],
          ),
        ],
      ),
    );

    final splitRows = await database.select(database.splits).get();
    final dayRows = await database.select(database.dayPlans).get();
    final plannedRows = await database.select(database.plannedExercises).get();

    expect(splitRows, hasLength(1));
    expect(splitRows.single.id, splitId);
    expect(dayRows, hasLength(2));
    expect(plannedRows, hasLength(3));
  });

  test('createSplit validates input constraints', () async {
    final exercises = await _seedExercises(exerciseRepository);
    final exerciseId = exercises.first.id;

    expect(
      () => splitRepository.createSplit(
        const SplitDraftInput(name: '', days: []),
      ),
      throwsArgumentError,
    );

    expect(
      () => splitRepository.createSplit(
        SplitDraftInput(
          name: 'Bad Days',
          days: [
            DayPlanDraftInput(
              dayIndex: 2,
              title: 'Upper',
              plannedExercises: [
                PlannedExerciseDraftInput(
                  orderIndex: 1,
                  exerciseId: exerciseId,
                  targetSets: 3,
                  repMin: 6,
                  repMax: 10,
                ),
              ],
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => splitRepository.createSplit(
        SplitDraftInput(
          name: 'Bad Reps',
          days: [
            DayPlanDraftInput(
              dayIndex: 1,
              title: 'Upper',
              plannedExercises: [
                PlannedExerciseDraftInput(
                  orderIndex: 1,
                  exerciseId: exerciseId,
                  targetSets: 3,
                  repMin: 10,
                  repMax: 8,
                ),
              ],
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => splitRepository.createSplit(
        SplitDraftInput(
          name: 'Bad Rest',
          days: [
            DayPlanDraftInput(
              dayIndex: 1,
              title: 'Upper',
              plannedExercises: [
                PlannedExerciseDraftInput(
                  orderIndex: 1,
                  exerciseId: exerciseId,
                  targetSets: 3,
                  repMin: 6,
                  repMax: 10,
                  restSeconds: -1,
                ),
              ],
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => splitRepository.createSplit(
        SplitDraftInput(
          name: 'Bad RPE',
          days: [
            DayPlanDraftInput(
              dayIndex: 1,
              title: 'Upper',
              plannedExercises: [
                PlannedExerciseDraftInput(
                  orderIndex: 1,
                  exerciseId: exerciseId,
                  targetSets: 3,
                  repMin: 6,
                  repMax: 10,
                  targetRpe: 11,
                ),
              ],
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('updateSplit replaces days and planned exercises', () async {
    final exercises = await _seedExercises(exerciseRepository);
    final splitId = await splitRepository.createSplit(
      SplitDraftInput(
        name: 'Original',
        days: [
          DayPlanDraftInput(
            dayIndex: 1,
            title: 'Day 1',
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

    nowMs = DateTime(2026, 2, 20, 11, 0).millisecondsSinceEpoch;
    await splitRepository.updateSplit(
      splitId,
      SplitDraftInput(
        name: 'Updated',
        days: [
          DayPlanDraftInput(
            dayIndex: 1,
            title: 'Upper A',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[1].id,
                targetSets: 4,
                repMin: 5,
                repMax: 8,
              ),
            ],
          ),
          DayPlanDraftInput(
            dayIndex: 2,
            title: 'Lower A',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[2].id,
                targetSets: 3,
                repMin: 8,
                repMax: 12,
              ),
            ],
          ),
        ],
      ),
    );

    final details = await splitRepository.getSplitById(splitId);
    expect(details, isNotNull);
    expect(details!.name, 'Updated');
    expect(details.days, hasLength(2));
    expect(details.days[0].title, 'Upper A');
    expect(details.days[1].title, 'Lower A');
    expect(details.days[0].plannedExercises.single.exerciseId, exercises[1].id);
    expect(details.days[1].plannedExercises.single.exerciseId, exercises[2].id);
  });

  test('watchSplits returns splits ordered by updatedAt desc', () async {
    final exercises = await _seedExercises(exerciseRepository);

    nowMs = DateTime(2026, 2, 20, 9, 0).millisecondsSinceEpoch;
    final firstSplitId = await _createMinimalSplit(
      splitRepository,
      exercises[0].id,
    );

    nowMs = DateTime(2026, 2, 20, 10, 0).millisecondsSinceEpoch;
    final secondSplitId = await _createMinimalSplit(
      splitRepository,
      exercises[1].id,
    );

    final summaries = await splitRepository.watchSplits().first;

    expect(summaries, hasLength(2));
    expect(summaries.first.id, secondSplitId);
    expect(summaries.last.id, firstSplitId);
  });

  test('watchSplits includes total planned sets and last logged timestamp', () async {
    final exercises = await _seedExercises(exerciseRepository);

    nowMs = DateTime(2026, 2, 20, 9, 0).millisecondsSinceEpoch;
    final splitId = await splitRepository.createSplit(
      SplitDraftInput(
        name: 'Upper A/B',
        days: [
          DayPlanDraftInput(
            dayIndex: 1,
            title: 'Upper A',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[0].id,
                targetSets: 3,
                repMin: 6,
                repMax: 10,
              ),
              PlannedExerciseDraftInput(
                orderIndex: 2,
                exerciseId: exercises[1].id,
                targetSets: 2,
                repMin: 8,
                repMax: 12,
              ),
            ],
          ),
        ],
      ),
    );
    final otherSplitId = await _createMinimalSplit(splitRepository, exercises[2].id);

    await database.into(database.workoutSessions).insert(
      WorkoutSessionsCompanion.insert(
        id: 'session_1',
        sessionType: 'split_day',
        splitId: Value(splitId),
        dayIndex: const Value(1),
        sessionName: const Value('Upper A'),
        startedAt: 1000,
        endedAt: 2000,
      ),
    );
    await database.into(database.workoutSessions).insert(
      WorkoutSessionsCompanion.insert(
        id: 'session_2',
        sessionType: 'split_day',
        splitId: Value(splitId),
        dayIndex: const Value(1),
        sessionName: const Value('Upper A'),
        startedAt: 3000,
        endedAt: 4000,
      ),
    );
    await database.into(database.workoutSessions).insert(
      WorkoutSessionsCompanion.insert(
        id: 'session_3',
        sessionType: 'free',
        splitId: Value(splitId),
        dayIndex: const Value(1),
        sessionName: const Value('Ignored'),
        startedAt: 5000,
        endedAt: 6000,
      ),
    );

    final summaries = await splitRepository.watchSplits().first;
    final summaryById = {for (final summary in summaries) summary.id: summary};

    expect(summaryById[splitId], isNotNull);
    expect(summaryById[splitId]!.totalSets, 5);
    expect(summaryById[splitId]!.lastLoggedAt, 4000);

    expect(summaryById[otherSplitId], isNotNull);
    expect(summaryById[otherSplitId]!.totalSets, 3);
    expect(summaryById[otherSplitId]!.lastLoggedAt, isNull);
  });

  test('setActiveSplit ensures exactly one active split', () async {
    final exercises = await _seedExercises(exerciseRepository);

    final firstSplitId = await _createMinimalSplit(
      splitRepository,
      exercises[0].id,
    );
    final secondSplitId = await _createMinimalSplit(
      splitRepository,
      exercises[1].id,
    );

    await splitRepository.setActiveSplit(firstSplitId);
    await splitRepository.setActiveSplit(secondSplitId);

    final activeSplits = await (database.select(
      database.splits,
    )..where((tbl) => tbl.isActive.equals(true))).get();

    expect(activeSplits, hasLength(1));
    expect(activeSplits.single.id, secondSplitId);
  });

  test('deleteSplit cascades to dayPlans and plannedExercises', () async {
    final exercises = await _seedExercises(exerciseRepository);

    final splitId = await splitRepository.createSplit(
      SplitDraftInput(
        name: 'Cascade Test',
        days: [
          DayPlanDraftInput(
            dayIndex: 1,
            title: 'Day 1',
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

    await splitRepository.deleteSplit(splitId);

    final splitRows = await database.select(database.splits).get();
    final dayRows = await database.select(database.dayPlans).get();
    final plannedRows = await database.select(database.plannedExercises).get();

    expect(splitRows, isEmpty);
    expect(dayRows, isEmpty);
    expect(plannedRows, isEmpty);
  });

  test('getSplitById returns day and planned exercise order', () async {
    final exercises = await _seedExercises(exerciseRepository);

    final splitId = await splitRepository.createSplit(
      SplitDraftInput(
        name: 'Ordering Test',
        days: [
          DayPlanDraftInput(
            dayIndex: 2,
            title: 'Day 2',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[2].id,
                targetSets: 3,
                repMin: 8,
                repMax: 12,
              ),
            ],
          ),
          DayPlanDraftInput(
            dayIndex: 1,
            title: 'Day 1',
            plannedExercises: [
              PlannedExerciseDraftInput(
                orderIndex: 2,
                exerciseId: exercises[1].id,
                targetSets: 3,
                repMin: 8,
                repMax: 12,
              ),
              PlannedExerciseDraftInput(
                orderIndex: 1,
                exerciseId: exercises[0].id,
                targetSets: 4,
                repMin: 5,
                repMax: 8,
              ),
            ],
          ),
        ],
      ),
    );

    final details = await splitRepository.getSplitById(splitId);

    expect(details, isNotNull);
    expect(details!.days, hasLength(2));
    expect(details.days[0].dayIndex, 1);
    expect(details.days[1].dayIndex, 2);
    expect(details.days[0].plannedExercises, hasLength(2));
    expect(details.days[0].plannedExercises[0].orderIndex, 1);
    expect(details.days[0].plannedExercises[1].orderIndex, 2);
    expect(details.days[0].plannedExercises[0].exerciseName, exercises[0].name);
  });
}

Future<List<ExerciseWithLabels>> _seedExercises(
  DriftExerciseRepository repository,
) async {
  await repository.seedIfEmpty();
  return repository.watchExercises().first;
}

Future<String> _createMinimalSplit(
  DriftSplitRepository repository,
  String exerciseId,
) {
  return repository.createSplit(
    SplitDraftInput(
      name: 'Simple Split',
      days: [
        DayPlanDraftInput(
          dayIndex: 1,
          title: 'Day 1',
          plannedExercises: [
            PlannedExerciseDraftInput(
              orderIndex: 1,
              exerciseId: exerciseId,
              targetSets: 3,
              repMin: 6,
              repMax: 10,
            ),
          ],
        ),
      ],
    ),
  );
}
