import 'package:flutter/material.dart';

class LabelPillSelector extends StatefulWidget {
  const LabelPillSelector({
    required this.availableLabels,
    required this.selectedLabels,
    required this.onSelectedLabelsChanged,
    required this.onCreateLabel,
    super.key,
    this.searchHintText = 'Search labels',
    this.emptyText = 'No labels available yet.',
    this.autoSelectCreatedLabel = true,
  });

  final List<String> availableLabels;
  final List<String> selectedLabels;
  final ValueChanged<List<String>> onSelectedLabelsChanged;
  final Future<bool> Function(String label) onCreateLabel;
  final String searchHintText;
  final String emptyText;
  final bool autoSelectCreatedLabel;

  @override
  State<LabelPillSelector> createState() => _LabelPillSelectorState();
}

class _LabelPillSelectorState extends State<LabelPillSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addActionColor = Theme.of(context).colorScheme.primary;
    final selected = {...widget.selectedLabels};
    final labels = <String>{...widget.availableLabels, ...selected}.toList()
      ..sort();
    final filtered = labels
        .where((label) => label.contains(_query.toLowerCase()))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('label_selector_search'),
          controller: _searchController,
          decoration: InputDecoration(
            labelText: widget.searchHintText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _query = value.trim().toLowerCase();
            });
          },
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty && selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.emptyText),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...filtered.map(
              (label) => FilterChip(
                selected: selected.contains(label),
                label: Text(label),
                onSelected: (isSelected) {
                  final next = {...selected};
                  if (isSelected) {
                    next.add(label);
                  } else {
                    next.remove(label);
                  }
                  final output = next.toList()..sort();
                  widget.onSelectedLabelsChanged(output);
                },
              ),
            ),
            ActionChip(
              key: const Key('label_selector_add'),
              label: Text(
                'ADD LABEL',
                style: TextStyle(color: addActionColor),
              ),
              avatar: Icon(Icons.add, size: 18, color: addActionColor),
              onPressed: () => _openAddDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    String labelInput = '';
    String? createdLabel;

    createdLabel = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Label'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Label name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => labelInput = value,
            onSubmitted: (_) {
              final normalized = labelInput.trim().toLowerCase();
              if (normalized.isEmpty) {
                return;
              }
              Navigator.of(context).pop(normalized);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = labelInput.trim().toLowerCase();
                if (normalized.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(normalized);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (createdLabel == null || createdLabel.isEmpty) {
      return;
    }

    final created = await widget.onCreateLabel(createdLabel);
    if (!created) {
      return;
    }

    if (!mounted || !widget.autoSelectCreatedLabel) {
      return;
    }

    final next = {...widget.selectedLabels, createdLabel}.toList()..sort();
    widget.onSelectedLabelsChanged(next);
  }
}
