import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../l10n/app_localizations.dart';
import 'exercise_repository.dart';

class LabelsScreen extends ConsumerStatefulWidget {
  const LabelsScreen({super.key});

  @override
  ConsumerState<LabelsScreen> createState() => _LabelsScreenState();
}

enum _UndoType { addLabel, deleteCustom }

class _UndoOperation {
  _UndoOperation.addLabel(this.labelName)
    : type = _UndoType.addLabel,
      deletedSnapshot = null;

  _UndoOperation.deleteCustom(DeletedCustomLabelSnapshot snapshot)
    : type = _UndoType.deleteCustom,
      labelName = snapshot.labelName,
      deletedSnapshot = snapshot;

  final _UndoType type;
  final String labelName;
  final DeletedCustomLabelSnapshot? deletedSnapshot;
}

class _LabelsScreenState extends ConsumerState<LabelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_UndoOperation> _undoStack = [];
  final List<_UndoOperation> _redoStack = [];
  bool _isMutating = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seedState = ref.watch(seedDataProvider);
    final catalogState = ref.watch(labelCatalogProvider);
    final addActionColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('Labels'))),
      body: seedState.when(
        data: (_) => catalogState.when(
          data: (catalog) {
            final filtered = _filteredCatalog(catalog);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(text: l10n.tr('Create labels with ')),
                      TextSpan(
                        text: l10n.tr('ADD LABEL'),
                        style: TextStyle(
                          color: addActionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tr('Only added labels can be deleted.'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('labels_search_field'),
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: l10n.tr('Search labels'),
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
                        l10n.tr('ADD LABEL'),
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
                      onPressed: (_undoStack.isEmpty || _isMutating)
                          ? null
                          : _undoLast,
                      icon: const Icon(Icons.undo),
                      label: Text(l10n.tr('Undo')),
                    ),
                    OutlinedButton.icon(
                      key: const Key('labels_redo_button'),
                      onPressed: (_redoStack.isEmpty || _isMutating)
                          ? null
                          : _redoLast,
                      icon: const Icon(Icons.redo),
                      label: Text(l10n.tr('Redo')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        l10n.tr('No labels match the current filter.'),
                      ),
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
          error: (error, _) => Center(
            child: Text(
              l10n.format('Failed to load labels: {error}', {'error': error}),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            l10n.format('Failed to initialize labels: {error}', {
              'error': error,
            }),
          ),
        ),
      ),
    );
  }

  List<LabelCatalogEntry> _filteredCatalog(List<LabelCatalogEntry> catalog) {
    final visible = catalog.where((entry) => !entry.isHidden);
    final l10n = context.l10n;
    final byQuery = visible.where(
      (entry) =>
          l10n.localizeLabelName(entry.name).toLowerCase().contains(_query),
    );
    final output = byQuery.toList()
      ..sort(
        (a, b) => l10n
            .localizeLabelName(a.name)
            .compareTo(l10n.localizeLabelName(b.name)),
      );
    return output;
  }

  Widget _buildLabelPill(BuildContext context, LabelCatalogEntry entry) {
    if (entry.isStandard) {
      return InputChip(
        label: Text(context.l10n.localizeLabelName(entry.name)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        onPressed: _isMutating ? null : () {},
        isEnabled: !_isMutating,
      );
    }

    return InputChip(
      label: Text(context.l10n.localizeLabelName(entry.name)),
      onDeleted: _isMutating ? null : () => _confirmDeleteCustom(entry),
      deleteIcon: _DeleteCircleIcon(key: Key('label_remove_${entry.name}')),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onPressed: _isMutating ? null : () {},
      isEnabled: !_isMutating,
    );
  }

  Future<void> _openAddDialog() async {
    final l10n = context.l10n;
    String input = '';
    final created = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tr('Create Label')),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.tr('Label name'),
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
            child: Text(l10n.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final normalized = input.trim().toLowerCase();
              if (normalized.isEmpty) {
                return;
              }
              Navigator.of(context).pop(normalized);
            },
            child: Text(l10n.tr('Add')),
          ),
        ],
      ),
    );

    if (created == null || created.isEmpty) {
      return;
    }

    setState(() => _isMutating = true);
    try {
      final wasCreated = await ref
          .read(exerciseRepositoryProvider)
          .createLabel(created);
      if (wasCreated) {
        _undoStack.add(_UndoOperation.addLabel(created));
        _redoStack.clear();
      } else {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('Label already exists or is standard.')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _confirmDeleteCustom(LabelCatalogEntry entry) async {
    if (_isMutating || entry.isStandard) {
      return;
    }

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          context.l10n.tr(
            'Are you sure to delete this label? When you exit the Labels screen, it will not be possible to restore it.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.tr('Delete')),
          ),
        ],
      ),
    );

    if (shouldProceed != true) {
      return;
    }

    setState(() => _isMutating = true);
    try {
      final snapshot = await ref
          .read(exerciseRepositoryProvider)
          .deleteCustomLabel(entry.name);
      if (snapshot != null) {
        _undoStack.add(_UndoOperation.deleteCustom(snapshot));
        _redoStack.clear();
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
          final deleted = await repository.deleteCustomLabel(
            operation.labelName,
          );
          if (deleted != null) {
            _redoStack.add(operation);
          }
          break;
        case _UndoType.deleteCustom:
          await repository.restoreDeletedCustomLabel(
            operation.deletedSnapshot!,
          );
          _redoStack.add(operation);
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _redoLast() async {
    if (_redoStack.isEmpty || _isMutating) {
      return;
    }

    final operation = _redoStack.removeLast();
    setState(() => _isMutating = true);
    try {
      final repository = ref.read(exerciseRepositoryProvider);
      switch (operation.type) {
        case _UndoType.addLabel:
          final recreated = await repository.createLabel(operation.labelName);
          if (recreated) {
            _undoStack.add(operation);
          }
          break;
        case _UndoType.deleteCustom:
          final snapshot = await repository.deleteCustomLabel(
            operation.labelName,
          );
          if (snapshot != null) {
            _undoStack.add(_UndoOperation.deleteCustom(snapshot));
          }
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: Icon(Icons.close, size: 12),
      ),
    );
  }
}
