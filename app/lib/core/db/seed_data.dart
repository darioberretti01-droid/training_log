class SeedExercise {
  const SeedExercise({
    required this.id,
    required this.name,
    required this.labels,
  });

  final String id;
  final String name;
  final List<String> labels;
}

const seededExercises = <SeedExercise>[
  SeedExercise(
    id: 'back_squat',
    name: 'Back Squat',
    labels: ['legs', 'quads', 'glutes', 'abs', 'compound'],
  ),
  SeedExercise(
    id: 'front_squat',
    name: 'Front Squat',
    labels: ['legs', 'quads', 'glutes', 'abs', 'compound'],
  ),
  SeedExercise(
    id: 'leg_press',
    name: 'Leg Press',
    labels: ['legs', 'quads', 'glutes', 'compound'],
  ),
  SeedExercise(
    id: 'romanian_deadlift',
    name: 'Romanian Deadlift',
    labels: [
      'legs',
      'hamstrings',
      'glutes',
      'back',
      'forearms',
      'abs',
      'posterior chain',
      'compound',
    ],
  ),
  SeedExercise(
    id: 'conventional_deadlift',
    name: 'Conventional Deadlift',
    labels: [
      'pull',
      'back',
      'hamstrings',
      'glutes',
      'forearms',
      'abs',
      'posterior chain',
      'compound',
    ],
  ),
  SeedExercise(
    id: 'bench_press',
    name: 'Barbell Bench Press',
    labels: ['push', 'chest', 'triceps', 'compound'],
  ),
  SeedExercise(
    id: 'incline_dumbbell_press',
    name: 'Incline Dumbbell Press',
    labels: ['push', 'chest', 'upper pecs', 'compound'],
  ),
  SeedExercise(
    id: 'overhead_press',
    name: 'Overhead Press',
    labels: ['push', 'shoulders', 'triceps', 'abs', 'compound'],
  ),
  SeedExercise(
    id: 'dips',
    name: 'Dips',
    labels: ['push', 'chest', 'triceps', 'compound'],
  ),
  SeedExercise(
    id: 'lateral_raise',
    name: 'Dumbbell Lateral Raise',
    labels: ['push', 'shoulders', 'isolation'],
  ),
  SeedExercise(
    id: 'pull_up',
    name: 'Pull-Up',
    labels: ['pull', 'back', 'lats', 'biceps', 'forearms', 'compound'],
  ),
  SeedExercise(
    id: 'lat_pulldown',
    name: 'Lat Pulldown',
    labels: ['pull', 'back', 'lats', 'biceps', 'forearms', 'compound'],
  ),
  SeedExercise(
    id: 'barbell_row',
    name: 'Barbell Row',
    labels: [
      'pull',
      'back',
      'upper back',
      'lats',
      'biceps',
      'forearms',
      'compound',
    ],
  ),
  SeedExercise(
    id: 'seated_cable_row',
    name: 'Seated Cable Row',
    labels: [
      'pull',
      'back',
      'upper back',
      'lats',
      'biceps',
      'forearms',
      'compound',
    ],
  ),
  SeedExercise(
    id: 'face_pull',
    name: 'Face Pull',
    labels: [
      'pull',
      'back',
      'rear delts',
      'upper back',
      'forearms',
      'isolation',
    ],
  ),
  SeedExercise(
    id: 'barbell_curl',
    name: 'Barbell Curl',
    labels: ['pull', 'arms', 'biceps', 'forearms', 'isolation'],
  ),
  SeedExercise(
    id: 'incline_dumbbell_curl',
    name: 'Incline Dumbbell Curl',
    labels: ['pull', 'arms', 'biceps', 'forearms', 'isolation'],
  ),
  SeedExercise(
    id: 'triceps_pushdown',
    name: 'Triceps Pushdown',
    labels: ['push', 'arms', 'triceps', 'isolation'],
  ),
  SeedExercise(
    id: 'skull_crusher',
    name: 'Skull Crusher',
    labels: ['push', 'arms', 'triceps', 'isolation'],
  ),
  SeedExercise(
    id: 'standing_calf_raise',
    name: 'Standing Calf Raise',
    labels: ['legs', 'calves', 'isolation'],
  ),
];

String labelIdFromName(String name) {
  final normalized = name.toLowerCase().trim();
  final cleaned = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return cleaned
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
