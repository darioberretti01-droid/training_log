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
    labels: ['legs', 'quads', 'compound'],
  ),
  SeedExercise(
    id: 'front_squat',
    name: 'Front Squat',
    labels: ['legs', 'quads', 'compound'],
  ),
  SeedExercise(
    id: 'leg_press',
    name: 'Leg Press',
    labels: ['legs', 'quads', 'compound'],
  ),
  SeedExercise(
    id: 'romanian_deadlift',
    name: 'Romanian Deadlift',
    labels: ['legs', 'hamstrings', 'posterior chain', 'compound'],
  ),
  SeedExercise(
    id: 'conventional_deadlift',
    name: 'Conventional Deadlift',
    labels: ['pull', 'posterior chain', 'compound'],
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
    labels: ['push', 'shoulders', 'triceps', 'compound'],
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
    labels: ['pull', 'lats', 'biceps', 'compound'],
  ),
  SeedExercise(
    id: 'lat_pulldown',
    name: 'Lat Pulldown',
    labels: ['pull', 'lats', 'biceps', 'compound'],
  ),
  SeedExercise(
    id: 'barbell_row',
    name: 'Barbell Row',
    labels: ['pull', 'upper back', 'lats', 'compound'],
  ),
  SeedExercise(
    id: 'seated_cable_row',
    name: 'Seated Cable Row',
    labels: ['pull', 'upper back', 'lats', 'compound'],
  ),
  SeedExercise(
    id: 'face_pull',
    name: 'Face Pull',
    labels: ['pull', 'rear delts', 'upper back', 'isolation'],
  ),
  SeedExercise(
    id: 'barbell_curl',
    name: 'Barbell Curl',
    labels: ['pull', 'arms', 'biceps', 'isolation'],
  ),
  SeedExercise(
    id: 'incline_dumbbell_curl',
    name: 'Incline Dumbbell Curl',
    labels: ['pull', 'arms', 'biceps', 'isolation'],
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
  return cleaned.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
}
