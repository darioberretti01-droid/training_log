import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/app.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';

void main() {
  testWidgets('App boots and shows exercise list shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(
              const [
                ExerciseWithLabels(
                  id: 'bench_press',
                  name: 'Barbell Bench Press',
                  labels: ['push', 'chest', 'triceps'],
                ),
              ],
            ),
          ),
        ],
        child: const TrainingLogApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Training Log'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
  });
}
