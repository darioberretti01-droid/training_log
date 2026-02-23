import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? _,
        ]) async {
          final outputDir = Directory(p.join('screenshots', 'current'));
          if (!outputDir.existsSync()) {
            outputDir.createSync(recursive: true);
          }
          final file = File(p.join(outputDir.path, '$screenshotName.png'));
          await file.writeAsBytes(screenshotBytes, flush: true);
          return true;
        },
  );
}
