import 'package:flutter/material.dart';

import '../../core/widgets/label_pill_selector.dart';
import 'split_volume.dart';

class SplitBuilderMuscleVolumeCard extends StatefulWidget {
  const SplitBuilderMuscleVolumeCard({
    required this.summary,
    required this.availableControlLabels,
    required this.selectedControlLabels,
    required this.onControlLabelsChanged,
    required this.onCreateControlLabel,
    super.key,
  });

  final SplitMuscleVolumeSummary summary;
  final List<String> availableControlLabels;
  final List<String> selectedControlLabels;
  final ValueChanged<List<String>> onControlLabelsChanged;
  final Future<bool> Function(String label) onCreateControlLabel;

  @override
  State<SplitBuilderMuscleVolumeCard> createState() =>
      _SplitBuilderMuscleVolumeCardState();
}

class _SplitBuilderMuscleVolumeCardState extends State<SplitBuilderMuscleVolumeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('split_builder_volume_overview'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Volume by muscle (sets)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('split_builder_volume_toggle'),
                  tooltip: _isExpanded
                      ? 'Collapse volume by muscle'
                      : 'Expand volume by muscle',
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 4),
              Text(
                'Based on exercise labels. Each exercise contributes all sets '
                'to each selected control label it has.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Whole split (${widget.summary.totalPlannedSets} planned sets)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    key: const Key('split_volume_control_labels_button'),
                    onPressed: () => _openControlLabelsDialog(context),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Control labels'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (!widget.summary.hasTrackedMuscles)
                const Text(
                  'Select at least one control label to track muscle volume.',
                )
              else ...[
                _VolumeBars(
                  volumes: widget.summary.totalMuscleVolumes,
                  emptyText: 'No tracked control labels in this split yet.',
                ),
                const SizedBox(height: 12),
                Text('By day', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...widget.summary.daySummaries.map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BuilderDayMuscleVolumeCard(day: day),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openControlLabelsDialog(BuildContext context) async {
    final draftSelection = [...widget.selectedControlLabels];
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              key: const Key('split_volume_control_labels_dialog'),
              title: const Text('Control Labels'),
              content: SizedBox(
                width: 420,
                child: LabelPillSelector(
                  availableLabels: widget.availableControlLabels,
                  selectedLabels: draftSelection,
                  onSelectedLabelsChanged: (labels) {
                    setDialogState(() {
                      draftSelection
                        ..clear()
                        ..addAll(labels);
                    });
                  },
                  onCreateLabel: widget.onCreateControlLabel,
                  searchHintText: 'Search control labels',
                  emptyText: 'No labels available.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onControlLabelsChanged(draftSelection);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BuilderDayMuscleVolumeCard extends StatelessWidget {
  const _BuilderDayMuscleVolumeCard({required this.day});

  final DayMuscleVolumeSummary day;

  @override
  Widget build(BuildContext context) {
    final dayVolumes = day.muscleVolumes
        .where((volume) => volume.setCount > 0)
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.displayLabel} (${day.plannedSetCount} sets)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _VolumeBars(
              volumes: dayVolumes,
              emptyText: 'No selected control labels present in this day.',
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeBars extends StatelessWidget {
  const _VolumeBars({required this.volumes, required this.emptyText});

  final List<MuscleSetVolume> volumes;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (volumes.isEmpty) {
      return Text(emptyText);
    }

    final maxSets = volumes
        .map((entry) => entry.setCount)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: volumes
          .map(
            (volume) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      volume.muscleLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: maxSets == 0 ? 0 : volume.setCount / maxSets,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${volume.setCount}'),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class SplitDetailMuscleVolumeCard extends StatelessWidget {
  const SplitDetailMuscleVolumeCard({required this.summary, super.key});

  final SplitMuscleVolumeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('split_detail_volume_overview'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volume by muscle (sets)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (!summary.hasTrackedMuscles)
              const Text('No control labels selected.')
            else ...[
              Text(
                'Whole split: ${_inlineVolume(summary.totalMuscleVolumes, maxItems: 8)}',
              ),
              const SizedBox(height: 6),
              ...summary.daySummaries.map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${day.displayLabel}: '
                    '${_inlineVolume(_nonZero(day.muscleVolumes), maxItems: 8)}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _inlineVolume(List<MuscleSetVolume> volumes, {required int maxItems}) {
  if (volumes.isEmpty) {
    return 'No tracked labels';
  }

  final shown = volumes.take(maxItems).toList(growable: false);
  final parts = shown
      .map((volume) => '${volume.muscleLabel} ${volume.setCount}')
      .toList(growable: false);
  final remaining = volumes.length - shown.length;
  if (remaining > 0) {
    parts.add('+$remaining more');
  }
  return parts.join(', ');
}

List<MuscleSetVolume> _nonZero(List<MuscleSetVolume> volumes) {
  return volumes.where((entry) => entry.setCount > 0).toList(growable: false);
}
