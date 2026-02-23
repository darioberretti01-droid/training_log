import 'dart:io';

import 'package:path/path.dart' as p;

import '../integration_test/screenshots_manifest.dart';

void main() {
  final scriptDir = p.dirname(Platform.script.toFilePath());
  final appDir = p.normalize(p.join(scriptDir, '..'));
  final docsDir = p.normalize(p.join(appDir, '..', 'docs'));
  final outputPath = p.join(docsDir, '05_screenshots.md');
  final outputFile = File(outputPath);

  final sorted = [...screenshotManifest]
    ..sort((a, b) => a.order.compareTo(b.order));

  final buffer = StringBuffer()
    ..writeln('# 05 - Screenshots')
    ..writeln()
    ..writeln(
      'Auto-generated from `app/integration_test/screenshots_manifest.dart`.',
    )
    ..writeln()
    ..writeln('| Order | ID | Title | Scenario | Group | Preview |')
    ..writeln('| --- | --- | --- | --- | --- | --- |');

  for (final entry in sorted) {
    final imagePath = '../app/screenshots/current/${entry.id}.png';
    buffer.writeln(
      '| ${entry.order} | `${entry.id}` | ${entry.title} | `${entry.scenario.name}` | `${entry.routeGroup}` | ![${entry.id}]($imagePath) |',
    );
  }

  outputFile.createSync(recursive: true);
  outputFile.writeAsStringSync(buffer.toString());

  stdout.writeln('Generated $outputPath');
}
