import 'dart:io';

import '../integration_test/screenshots_manifest.dart';

void main() {
  final outputDir = Directory('screenshots/current');
  if (!outputDir.existsSync()) {
    stderr.writeln(
      'Missing output directory: ${outputDir.path}. Generate screenshots first.',
    );
    exit(1);
  }

  final expectedIds = <String>{};
  final duplicateIds = <String>{};
  for (final entry in screenshotManifest) {
    if (!expectedIds.add(entry.id)) {
      duplicateIds.add(entry.id);
    }
  }

  if (duplicateIds.isNotEmpty) {
    stderr.writeln('Duplicate screenshot ids in manifest:');
    for (final id in duplicateIds.toList()..sort()) {
      stderr.writeln('- $id');
    }
    exit(1);
  }

  final expectedFiles = expectedIds.map((id) => '$id.png').toSet();
  final actualFiles = outputDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .map((file) => file.uri.pathSegments.last)
      .toSet();

  final missingFiles = expectedFiles.difference(actualFiles).toList()..sort();
  final orphanFiles = actualFiles.difference(expectedFiles).toList()..sort();

  if (missingFiles.isEmpty && orphanFiles.isEmpty) {
    stdout.writeln(
      'Screenshots validated (${expectedFiles.length} files, no missing/orphans).',
    );
    return;
  }

  if (missingFiles.isNotEmpty) {
    stderr.writeln('Missing screenshots:');
    for (final fileName in missingFiles) {
      stderr.writeln('- $fileName');
    }
  }

  if (orphanFiles.isNotEmpty) {
    stderr.writeln('Orphan screenshots (not present in manifest):');
    for (final fileName in orphanFiles) {
      stderr.writeln('- $fileName');
    }
  }

  exit(1);
}
