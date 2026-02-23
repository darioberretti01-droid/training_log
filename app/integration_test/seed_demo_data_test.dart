import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/devtools/demo_fixture_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reset + seed demo fixture', (tester) async {
    final fixedNow = DateTime(2026, 2, 23, 9, 30);
    final container = ProviderContainer(
      overrides: [appClockProvider.overrideWithValue(() => fixedNow)],
    );
    addTearDown(container.dispose);

    await container
        .read(demoFixtureServiceProvider)
        .resetAndSeed(DemoFixtureScenario.baseRealistic, now: fixedNow);
  });
}
