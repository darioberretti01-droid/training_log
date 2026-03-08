import 'package:flutter/material.dart';

import '../../core/widgets/label_pill_selector.dart';
import '../../l10n/app_localizations.dart';
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

class _SplitBuilderMuscleVolumeCardState
    extends State<SplitBuilderMuscleVolumeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                    l10n.tr('Volume by muscle (sets)'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('split_builder_volume_toggle'),
                  tooltip: _isExpanded
                      ? l10n.tr('Collapse volume by muscle')
                      : l10n.tr('Expand volume by muscle'),
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
                l10n.tr(
                  'Based on exercise labels. Each exercise contributes all sets to each selected control label it has.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    l10n.format('Whole split ({count} planned sets)', {
                      'count': widget.summary.totalPlannedSets,
                    }),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    key: const Key('split_volume_control_labels_button'),
                    onPressed: () => _openControlLabelsDialog(context),
                    icon: const Icon(Icons.tune, size: 16),
                    label: Text(l10n.tr('Control labels')),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (!widget.summary.hasTrackedMuscles)
                Text(
                  l10n.tr(
                    'Select at least one control label to track muscle volume.',
                  ),
                )
              else ...[
                _VolumeBars(
                  volumes: widget.summary.totalMuscleVolumes,
                  emptyText: l10n.tr(
                    'No tracked control labels in this split yet.',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tr('By day'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
    final l10n = context.l10n;
    final draftSelection = [...widget.selectedControlLabels];
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              key: const Key('split_volume_control_labels_dialog'),
              title: Text(l10n.tr('Control Labels')),
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
                  searchHintText: l10n.tr('Search control labels'),
                  emptyText: l10n.tr('No labels available.'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.tr('Cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onControlLabelsChanged(draftSelection);
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.tr('Apply')),
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
    final l10n = context.l10n;
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
              l10n.format('{label} ({count} sets)', {
                'label': day.displayLabel,
                'count': day.plannedSetCount,
              }),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _VolumeBars(
              volumes: dayVolumes,
              emptyText: l10n.tr(
                'No selected control labels present in this day.',
              ),
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
    final l10n = context.l10n;

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
                      l10n.localizeLabelName(volume.muscleLabel),
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
    final l10n = context.l10n;
    return Card(
      key: const Key('split_detail_volume_overview'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('Volume by muscle (sets)'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (!summary.hasTrackedMuscles)
              Text(l10n.tr('No control labels selected.'))
            else ...[
              Text(
                l10n.format('Whole split: {value}', {
                  'value': _inlineVolume(
                    context,
                    summary.totalMuscleVolumes,
                    maxItems: 8,
                  ),
                }),
              ),
              const SizedBox(height: 6),
              ...summary.daySummaries.map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${day.displayLabel}: '
                    '${_inlineVolume(context, _nonZero(day.muscleVolumes), maxItems: 8)}',
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

String _inlineVolume(
  BuildContext context,
  List<MuscleSetVolume> volumes, {
  required int maxItems,
}) {
  if (volumes.isEmpty) {
    return context.l10n.tr('No tracked labels');
  }

  final l10n = context.l10n;
  final shown = volumes.take(maxItems).toList(growable: false);
  final parts = shown
      .map(
        (volume) =>
            '${l10n.localizeLabelName(volume.muscleLabel)} ${volume.setCount}',
      )
      .toList(growable: false);
  final remaining = volumes.length - shown.length;
  if (remaining > 0) {
    parts.add(l10n.format('+{count} more', {'count': remaining}));
  }
  return parts.join(', ');
}

List<MuscleSetVolume> _nonZero(List<MuscleSetVolume> volumes) {
  return volumes.where((entry) => entry.setCount > 0).toList(growable: false);
}
