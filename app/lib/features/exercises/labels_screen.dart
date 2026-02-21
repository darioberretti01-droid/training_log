import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/label_pill_selector.dart';

class LabelsScreen extends ConsumerStatefulWidget {
  const LabelsScreen({super.key});

  @override
  ConsumerState<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends ConsumerState<LabelsScreen> {
  final List<String> _selectedLabels = [];

  @override
  Widget build(BuildContext context) {
    final labelsState = ref.watch(allLabelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Labels')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Search labels, select multiple labels, and create new labels with +add.',
          ),
          const SizedBox(height: 12),
          labelsState.when(
            data: (allLabels) => LabelPillSelector(
              availableLabels: allLabels,
              selectedLabels: _selectedLabels,
              onSelectedLabelsChanged: (labels) {
                setState(() {
                  _selectedLabels
                    ..clear()
                    ..addAll(labels);
                });
              },
              onCreateLabel: (label) async {
                await ref.read(exerciseRepositoryProvider).createLabel(label);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Failed to load labels: $error'),
          ),
        ],
      ),
    );
  }
}
