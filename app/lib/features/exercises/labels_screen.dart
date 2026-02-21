import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import 'exercise_repository.dart';

class LabelsScreen extends ConsumerStatefulWidget {
  const LabelsScreen({super.key});

  @override
  ConsumerState<LabelsScreen> createState() => _LabelsScreenState();
}

enum _UndoType { addLabel, hideStandard, unhideStandard, deleteCustom }

class _UndoOperation {
  const _UndoOperation.addLabel(this.labelName)
    : type = _UndoType.addLabel,
      deletedSnapshot = null;

  const _UndoOperation.hideStandard(this.labelName)
    : type = _UndoType.hideStandard,
      deletedSnapshot = null;

  const _UndoOperation.unhideStandard(this.labelName)
    : type = _UndoType.unhideStandard,
      deletedSnapshot = null;

  const _UndoOperation.deleteCustom(this.deletedSnapshot)
    : type = _UndoType.deleteCustom,
      labelName = null;

  final _UndoType type;
  final String? labelName;
  final DeletedCustomLabelSnapshot? deletedSnapshot;
}

class _LabelsScreenState extends ConsumerState<LabelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_UndoOperation> _undoStack = [];
  bool _showHidden = false;
  bool _isMutating = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seedState = ref.watch(seedDataProvider);
    final catalogState = ref.watch(labelCatalogProvider);
    final addActionColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Labels')),
      body: seedState.when(
        data: (_) => catalogState.when(
          data: (catalog) {
            final filtered = _filteredCatalog(catalog);
            final hiddenCount = catalog.where((entry) => entry.isHidden).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Create labels with '),
                      TextSpan(
                        text: 'ADD LABEL',
                        style: TextStyle(
                          color: addActionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('labels_search_field'),
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search labels',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() => _query = value.trim().toLowerCase());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      key: const Key('labels_add_button'),
                      label: Text(
                        'ADD LABEL',
                        style: TextStyle(color: addActionColor),
                      ),
                      avatar: Icon(Icons.add, size: 18, color: addActionColor),
                      onPressed: _isMutating ? null : _openAddDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('labels_undo_button'),
                      onPressed:
                          (_undoStack.isEmpty || _isMutating) ? null : _undoLast,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('labels_toggle_hidden_button'),
                      onPressed: _isMutating
                          ? null
                          : () {
                              setState(() {
                                _showHidden = !_showHidden;
                              });
                            },
                      icon: Icon(
                        _showHidden ? Icons.visibility_off : Icons.visibility,
                      ),
                      label: Text(
                        _showHidden
                            ? 'Show visible labels'
                            : 'Show hidden labels ($hiddenCount)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('No labels match the current filter.'),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filtered
                        .map((entry) => _buildLabelPill(context, entry))
                        .toList(growable: false),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed to load labels: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to initialize labels: $error')),
      ),
    );
  }

  List<LabelCatalogEntry> _filteredCatalog(List<LabelCatalogEntry> catalog) {
    final byVisibility = catalog.where((entry) => entry.isHidden == _showHidden);
    final byQuery = byVisibility.where(
      (entry) => entry.name.contains(_query),
    );
    final output = byQuery.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return output;
  }

  Widget _buildLabelPill(BuildContext context, LabelCatalogEntry entry) {
    if (_showHidden) {
      return ActionChip(
        key: Key('label_restore_${entry.name}'),
        label: Text(entry.name),
        avatar: const Icon(Icons.restore, size: 16),
        onPressed: _isMutating ? null : () => _restoreHidden(entry),
      );
    }

    return InputChip(
      label: Text(entry.name),
      onDeleted: _isMutating ? null : () => _confirmDeleteOrHide(entry),
      deleteIcon: _DeleteCircleIcon(key: Key('label_remove_${entry.name}')),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onPressed: _isMutating ? null : () => _confirmDeleteOrHide(entry),
      isEnabled: !_isMutating,
    );
  }

  Future<void> _openAddDialog() async {
    String input = '';
    final created = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Label'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Label name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => input = value,
          onSubmitted: (_) {
            final normalized = input.trim().toLowerCase();
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
              final normalized = input.trim().toLowerCase();
              if (normalized.isEmpty) {
                return;
              }
              Navigator.of(context).pop(normalized);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (created == null || created.isEmpty) {
      return;
    }

    setState(() => _isMutating = true);
    try {
      final wasCreated = await ref.read(exerciseRepositoryProvider).createLabel(
            created,
          );
      if (wasCreated) {
        _undoStack.add(_UndoOperation.addLabel(created));
      } else {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Label already exists or is standard.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _confirmDeleteOrHide(LabelCatalogEntry entry) async {
    if (_isMutating) {
      return;
    }

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        if (entry.isStandard) {
          return AlertDialog(
            content: const Text(
              'This label is is a standard app label. It will not be deleted, but you can hide it. Hidden labels can always be restored',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hide'),
              ),
            ],
          );
        }

        return AlertDialog(
          content: const Text(
            'Are you sure to delete this label? When you exit the Labels screen, it will not be possible to restore it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldProceed != true) {
      return;
    }

    setState(() => _isMutating = true);
    try {
      final repository = ref.read(exerciseRepositoryProvider);
      if (entry.isStandard) {
        final hidden = await repository.hideStandardLabel(entry.name);
        if (hidden) {
          _undoStack.add(_UndoOperation.hideStandard(entry.name));
        }
      } else {
        final snapshot = await repository.deleteCustomLabel(entry.name);
        if (snapshot != null) {
          _undoStack.add(_UndoOperation.deleteCustom(snapshot));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _restoreHidden(LabelCatalogEntry entry) async {
    if (_isMutating) {
      return;
    }
    setState(() => _isMutating = true);
    try {
      final unhidden = await ref
          .read(exerciseRepositoryProvider)
          .unhideStandardLabel(entry.name);
      if (unhidden) {
        _undoStack.add(_UndoOperation.unhideStandard(entry.name));
      }
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _undoLast() async {
    if (_undoStack.isEmpty || _isMutating) {
      return;
    }

    final operation = _undoStack.removeLast();
    setState(() => _isMutating = true);
    try {
      final repository = ref.read(exerciseRepositoryProvider);
      switch (operation.type) {
        case _UndoType.addLabel:
          await repository.deleteCustomLabel(operation.labelName!);
          break;
        case _UndoType.hideStandard:
          await repository.unhideStandardLabel(operation.labelName!);
          break;
        case _UndoType.unhideStandard:
          await repository.hideStandardLabel(operation.labelName!);
          break;
        case _UndoType.deleteCustom:
          await repository.restoreDeletedCustomLabel(operation.deletedSnapshot!);
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }
}

class _DeleteCircleIcon extends StatelessWidget {
  const _DeleteCircleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: Icon(Icons.close, size: 12),
      ),
    );
  }
}
