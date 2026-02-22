import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';

class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key, this.title = 'Exercises'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const ExerciseListContent(),
    );
  }
}

enum _ExerciseDivision {
  muscles,
  pushPullLegs,
  upperLower,
  compoundIsolation,
  allExercises,
}

enum _ExercisePresentation { pills, list }

enum _ExerciseOrdering { alphabetic, createdAt, mostUsed }

class ExerciseListContent extends ConsumerStatefulWidget {
  const ExerciseListContent({super.key});

  @override
  ConsumerState<ExerciseListContent> createState() =>
      _ExerciseListContentState();
}

class _ExerciseListContentState extends ConsumerState<ExerciseListContent> {
  final TextEditingController _searchController = TextEditingController();
  _ExerciseDivision _division = _ExerciseDivision.muscles;
  _ExercisePresentation _presentation = _ExercisePresentation.pills;
  _ExerciseOrdering _ordering = _ExerciseOrdering.alphabetic;
  bool _ascending = true;
  bool _showHiddenExercises = false;
  bool _isDeleteMode = false;
  bool _isMutating = false;
  String? _armedExerciseId;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seedState = ref.watch(seedDataProvider);

    return seedState.when(
      data: (_) {
        final exercisesState = ref.watch(exercisesProvider);
        final createdAtMap = ref
            .watch(exerciseCreatedAtMapProvider)
            .maybeWhen(
              data: (value) => value,
              orElse: () => const <String, int>{},
            );
        final logCountMap = ref
            .watch(exerciseLogCountMapProvider)
            .maybeWhen(
              data: (value) => value,
              orElse: () => const <String, int>{},
            );
        return exercisesState.when(
          data: (exercises) =>
              _buildLoaded(context, exercises, createdAtMap, logCountMap),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: 'Failed to load exercises: $error',
            onRetry: () => ref.invalidate(exercisesProvider),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: 'Failed to initialize exercise data: $error',
        onRetry: () => ref.invalidate(seedDataProvider),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    List<ExerciseWithLabels> exercises,
    Map<String, int> createdAtMap,
    Map<String, int> logCountMap,
  ) {
    final addActionColor = Theme.of(context).colorScheme.primary;
    final items = _toFilteredItems(exercises, createdAtMap, logCountMap);
    final sections = _buildSections(items);
    final itemSectionCount = _itemSectionCount(sections);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_showHiddenExercises) {
          setState(() => _showHiddenExercises = false);
          return;
        }
        context.go('/home');
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _clearTransientSelections,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPossiblyBlurredTopControls(context, addActionColor),
            const SizedBox(height: 10),
            _buildToolbarLine(context),
            const SizedBox(height: 12),
            if (sections.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('No exercises match the current filter.'),
                ),
              )
            else
              ...sections.map(
                (section) => _buildSection(context, section, itemSectionCount),
              ),
          ],
        ),
      ),
    );
  }

  void _clearTransientSelections() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isDeleteMode || _armedExerciseId != null) {
      setState(() {
        _isDeleteMode = false;
        _armedExerciseId = null;
      });
    }
  }

  Widget _buildPossiblyBlurredTopControls(
    BuildContext context,
    Color addActionColor,
  ) {
    final controls = Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 10),
        _buildDivisionAndAddControls(context, addActionColor),
        const SizedBox(height: 8),
        _buildOrderingControls(),
      ],
    );

    if (!_isDeleteMode) {
      return controls;
    }

    return IgnorePointer(
      child: Opacity(
        opacity: 0.35,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: controls,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      key: const Key('exercises_search_field'),
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search exercises',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        setState(() => _query = value.trim().toLowerCase());
      },
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }

  Widget _buildDivisionAndAddControls(
    BuildContext context,
    Color addActionColor,
  ) {
    final divisionDropdown = DropdownButtonFormField<_ExerciseDivision>(
      key: const Key('exercises_grouping_dropdown'),
      initialValue: _division,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Division',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _ExerciseDivision.values
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(
                _divisionLabel(value),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _division = value);
      },
    );

    final addButton = ActionChip(
      key: const Key('exercises_add_button'),
      avatar: Icon(Icons.add, size: 18, color: addActionColor),
      label: Text('ADD EXERCISE', style: TextStyle(color: addActionColor)),
      onPressed: () => context.push('/exercises/new'),
    );

    return Row(
      children: [
        Expanded(child: divisionDropdown),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            alignment: Alignment.centerRight,
            fit: BoxFit.scaleDown,
            child: addButton,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderingControls() {
    final orderingDropdown = DropdownButtonFormField<_ExerciseOrdering>(
      key: const Key('exercises_order_dropdown'),
      initialValue: _ordering,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Ordering',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _ExerciseOrdering.values
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(
                _orderingLabel(value),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _ordering = value;
          _ascending = value == _ExerciseOrdering.alphabetic;
        });
      },
    );

    return Row(
      children: [
        Expanded(child: orderingDropdown),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('exercises_order_invert_button'),
          tooltip: _ascending ? 'Ascending' : 'Descending',
          onPressed: () => setState(() => _ascending = !_ascending),
          icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
        ),
      ],
    );
  }

  Widget _buildToolbarLine(BuildContext context) {
    Widget left = LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        return Row(
          children: [
            ToggleButtons(
              key: const Key('exercises_view_toggle'),
              constraints: const BoxConstraints(minWidth: 34, minHeight: 32),
              isSelected: [
                _presentation == _ExercisePresentation.pills,
                _presentation == _ExercisePresentation.list,
              ],
              onPressed: _isMutating
                  ? null
                  : (index) {
                      setState(() {
                        _presentation = index == 0
                            ? _ExercisePresentation.pills
                            : _ExercisePresentation.list;
                      });
                    },
              children: const [
                Icon(Icons.local_offer_outlined, size: 18),
                Icon(Icons.view_list_outlined, size: 18),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('exercises_toggle_hidden_button'),
                onPressed: _isMutating
                    ? null
                    : () {
                        setState(
                          () => _showHiddenExercises = !_showHiddenExercises,
                        );
                      },
                icon: Icon(
                  _showHiddenExercises
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 18,
                ),
                label: Text(
                  _showHiddenExercises
                      ? 'Visible'
                      : (isNarrow ? 'Hidden' : 'Hidden exercises'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (_isDeleteMode) {
      left = IgnorePointer(
        child: Opacity(
          opacity: 0.35,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: left,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('exercises_delete_mode_button'),
          tooltip: _isDeleteMode ? 'Exit delete mode' : 'Delete/hide mode',
          onPressed: _isMutating
              ? null
              : () {
                  setState(() {
                    _isDeleteMode = !_isDeleteMode;
                    _armedExerciseId = null;
                  });
                },
          icon: Icon(
            Icons.delete_outline,
            color: _isDeleteMode ? Theme.of(context).colorScheme.error : null,
          ),
        ),
      ],
    );
  }

  List<_ExerciseListItem> _toFilteredItems(
    List<ExerciseWithLabels> exercises,
    Map<String, int> createdAtMap,
    Map<String, int> logCountMap,
  ) {
    final filtered = <_ExerciseListItem>[];
    for (final exercise in exercises) {
      if (_showHiddenExercises && !exercise.isHidden) {
        continue;
      }
      if (!_showHiddenExercises && exercise.isHidden) {
        continue;
      }
      if (_query.isNotEmpty && !exercise.name.toLowerCase().contains(_query)) {
        continue;
      }
      final logCount = exercise.lookupExerciseIds.fold<int>(
        0,
        (sum, id) => sum + (logCountMap[id] ?? 0),
      );
      filtered.add(
        _ExerciseListItem(
          exercise: exercise,
          createdAtMs: createdAtMap[exercise.id] ?? 0,
          logCount: logCount,
        ),
      );
    }
    filtered.sort(_itemComparator);
    return filtered;
  }

  int _itemComparator(_ExerciseListItem a, _ExerciseListItem b) {
    int comparison;
    switch (_ordering) {
      case _ExerciseOrdering.alphabetic:
        comparison = a.nameLower.compareTo(b.nameLower);
        break;
      case _ExerciseOrdering.createdAt:
        comparison = a.createdAtMs.compareTo(b.createdAtMs);
        break;
      case _ExerciseOrdering.mostUsed:
        comparison = a.logCount.compareTo(b.logCount);
        break;
    }

    if (comparison == 0) {
      comparison = a.nameLower.compareTo(b.nameLower);
    }
    if (comparison == 0) {
      comparison = a.exercise.id.compareTo(b.exercise.id);
    }
    return _ascending ? comparison : -comparison;
  }

  List<_ExerciseSection> _buildSections(List<_ExerciseListItem> items) {
    final definitions = _divisionSections(_division);
    final byTitle = <String, List<_ExerciseListItem>>{
      for (final section in definitions) section.title: <_ExerciseListItem>[],
    };

    if (_division == _ExerciseDivision.allExercises) {
      byTitle[definitions.first.title]!.addAll(items);
      return [_ExerciseSection(title: definitions.first.title, items: items)];
    }

    final otherSection = definitions.last;
    for (final item in items) {
      if (_division == _ExerciseDivision.muscles) {
        final matches = <_DivisionSection>[];
        for (final section in definitions) {
          if (section.isOther) {
            continue;
          }
          if (item.matches(section.labelMatchers)) {
            matches.add(section);
          }
        }
        if (matches.isEmpty) {
          byTitle[otherSection.title]!.add(item);
          continue;
        }
        for (final section in matches) {
          byTitle[section.title]!.add(item);
        }
        continue;
      }

      _DivisionSection? matched;
      for (final section in definitions) {
        if (section.isOther) {
          continue;
        }
        if (item.matches(section.labelMatchers)) {
          matched = section;
          break;
        }
      }
      byTitle[matched?.title ?? otherSection.title]!.add(item);
    }

    final output = <_ExerciseSection>[];
    for (final section in definitions) {
      final sectionItems = byTitle[section.title]!;
      if (sectionItems.isEmpty) {
        continue;
      }
      output.add(_ExerciseSection(title: section.title, items: sectionItems));
    }
    return output;
  }

  Map<String, int> _itemSectionCount(List<_ExerciseSection> sections) {
    final counts = <String, int>{};
    for (final section in sections) {
      for (final item in section.items) {
        counts.update(
          item.exercise.id,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return counts;
  }

  Widget _buildSection(
    BuildContext context,
    _ExerciseSection section,
    Map<String, int> itemSectionCount,
  ) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: titleStyle),
          const SizedBox(height: 8),
          if (_presentation == _ExercisePresentation.pills)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: section.items
                  .map(
                    (item) => _buildExercisePill(
                      context,
                      item,
                      section.title,
                      itemSectionCount,
                    ),
                  )
                  .toList(growable: false),
            )
          else if (_isDeleteMode)
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(section.items.length, (index) {
                  final item = section.items[index];
                  final isLast = index == section.items.length - 1;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDeleteModeTile(
                        context,
                        item,
                        section.title,
                        itemSectionCount,
                      ),
                      if (!isLast) const Divider(height: 1),
                    ],
                  );
                }),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(section.items.length, (index) {
                  final item = section.items[index];
                  final isLast = index == section.items.length - 1;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        key: _exerciseKey(
                          prefix: 'exercise_list',
                          exerciseId: item.exercise.id,
                          sectionTitle: section.title,
                          itemSectionCount: itemSectionCount,
                        ),
                        title: Text(item.exercise.name),
                        subtitle: item.exercise.labels.isEmpty
                            ? null
                            : Text(item.exercise.labels.join(', ')),
                        onTap: _isMutating
                            ? null
                            : () => _handleExercisePressed(
                                context,
                                item.exercise,
                              ),
                      ),
                      if (!isLast) const Divider(height: 1),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExercisePill(
    BuildContext context,
    _ExerciseListItem item,
    String sectionTitle,
    Map<String, int> itemSectionCount,
  ) {
    final exercise = item.exercise;
    return ActionChip(
      key: _exerciseKey(
        prefix: 'exercise_pill',
        exerciseId: exercise.id,
        sectionTitle: sectionTitle,
        itemSectionCount: itemSectionCount,
      ),
      label: Text(exercise.name),
      onPressed: _isMutating
          ? null
          : () {
              if (_isDeleteMode) {
                _onDeleteModeExerciseTap(exercise);
              } else {
                _handleExercisePressed(context, exercise);
              }
            },
    );
  }

  Widget _buildDeleteModeTile(
    BuildContext context,
    _ExerciseListItem item,
    String sectionTitle,
    Map<String, int> itemSectionCount,
  ) {
    final exercise = item.exercise;
    final isArmed = _armedExerciseId == exercise.id;
    final errorContainer = Theme.of(context).colorScheme.errorContainer;

    return ListTile(
      key: _exerciseKey(
        prefix: 'exercise_delete_tile',
        exerciseId: exercise.id,
        sectionTitle: sectionTitle,
        itemSectionCount: itemSectionCount,
      ),
      tileColor: isArmed ? errorContainer.withValues(alpha: 0.65) : null,
      title: Text(exercise.name),
      subtitle: exercise.labels.isEmpty
          ? null
          : Text(exercise.labels.join(', ')),
      trailing: exercise.isStandard
          ? OutlinedButton(
              key: _exerciseKey(
                prefix: 'exercise_hide',
                exerciseId: exercise.id,
                sectionTitle: sectionTitle,
                itemSectionCount: itemSectionCount,
              ),
              onPressed: _isMutating
                  ? null
                  : () => _confirmHideOrRestoreStandardExercise(exercise),
              child: Text(exercise.isHidden ? 'RESTORE' : 'HIDE'),
            )
          : IconButton(
              key: _exerciseKey(
                prefix: 'exercise_delete',
                exerciseId: exercise.id,
                sectionTitle: sectionTitle,
                itemSectionCount: itemSectionCount,
              ),
              onPressed: _isMutating
                  ? null
                  : () => _confirmDeleteCustomExercise(exercise),
              icon: _DeleteCircleTrashIcon(
                color: isArmed ? Theme.of(context).colorScheme.error : null,
              ),
            ),
      onTap: _isMutating ? null : () => _onDeleteModeExerciseTap(exercise),
    );
  }

  Key _exerciseKey({
    required String prefix,
    required String exerciseId,
    required String sectionTitle,
    required Map<String, int> itemSectionCount,
  }) {
    final count = itemSectionCount[exerciseId] ?? 1;
    if (count <= 1) {
      return Key('${prefix}_$exerciseId');
    }
    final sectionToken = sectionTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return Key('${prefix}_${exerciseId}_$sectionToken');
  }

  void _onDeleteModeExerciseTap(ExerciseWithLabels exercise) {
    if (exercise.isStandard) {
      _confirmHideOrRestoreStandardExercise(exercise);
      return;
    }
    _confirmDeleteCustomExercise(exercise);
  }

  void _handleExercisePressed(
    BuildContext context,
    ExerciseWithLabels exercise,
  ) {
    if (_showHiddenExercises && exercise.isStandard && exercise.isHidden) {
      _confirmHideOrRestoreStandardExercise(exercise);
      return;
    }
    context.push('/exercises/${exercise.id}/history');
  }

  Future<void> _confirmDeleteCustomExercise(ExerciseWithLabels exercise) async {
    if (_isMutating || exercise.isStandard) {
      return;
    }

    setState(() => _armedExerciseId = exercise.id);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Are you sure to delete this exercise? When you exit the Exercises screen, it will not be possible to restore it.',
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
      ),
    );

    if (!mounted) {
      return;
    }

    if (shouldDelete == true) {
      setState(() => _isMutating = true);
      try {
        await ref
            .read(exerciseRepositoryProvider)
            .deleteCustomExercise(exercise.id);
      } finally {
        if (mounted) {
          setState(() => _isMutating = false);
        }
      }
    }

    if (mounted) {
      setState(() => _armedExerciseId = null);
    }
  }

  Future<void> _confirmHideOrRestoreStandardExercise(
    ExerciseWithLabels exercise,
  ) async {
    if (_isMutating || !exercise.isStandard) {
      return;
    }

    setState(() => _armedExerciseId = exercise.id);
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        if (exercise.isHidden) {
          return AlertDialog(
            content: const Text('Do you want to restore this exercise?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restore'),
              ),
            ],
          );
        }

        return AlertDialog(
          content: const Text(
            'This exercise is a standard app exercise. It will not be deleted, but you can hide it. Hidden exercises can always be restored',
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
      },
    );

    if (!mounted) {
      return;
    }

    if (shouldProceed == true) {
      setState(() => _isMutating = true);
      try {
        final repository = ref.read(exerciseRepositoryProvider);
        if (exercise.isHidden) {
          await repository.unhideStandardExercise(exercise.id);
        } else {
          await repository.hideStandardExercise(exercise.id);
        }
      } finally {
        if (mounted) {
          setState(() => _isMutating = false);
        }
      }
    }

    if (mounted) {
      setState(() => _armedExerciseId = null);
    }
  }
}

class _ExerciseListItem {
  _ExerciseListItem({
    required this.exercise,
    required this.createdAtMs,
    required this.logCount,
  }) : nameLower = exercise.name.toLowerCase(),
       labelsLower = exercise.labels
           .map((label) => label.toLowerCase())
           .toSet();

  final ExerciseWithLabels exercise;
  final int createdAtMs;
  final int logCount;
  final String nameLower;
  final Set<String> labelsLower;

  bool matches(Set<String> matchers) => labelsLower.any(matchers.contains);
}

class _ExerciseSection {
  const _ExerciseSection({required this.title, required this.items});

  final String title;
  final List<_ExerciseListItem> items;
}

class _DivisionSection {
  const _DivisionSection({
    required this.title,
    required this.labelMatchers,
    this.isOther = false,
  });

  final String title;
  final Set<String> labelMatchers;
  final bool isOther;
}

List<_DivisionSection> _divisionSections(_ExerciseDivision division) {
  switch (division) {
    case _ExerciseDivision.muscles:
      return const [
        _DivisionSection(
          title: 'Chest',
          labelMatchers: {'chest', 'upper pecs'},
        ),
        _DivisionSection(
          title: 'Back',
          labelMatchers: {'back', 'upper back', 'lats'},
        ),
        _DivisionSection(
          title: 'Shoulders',
          labelMatchers: {'shoulders', 'rear delts'},
        ),
        _DivisionSection(title: 'Quads', labelMatchers: {'quads'}),
        _DivisionSection(title: 'Glutes', labelMatchers: {'glutes'}),
        _DivisionSection(title: 'Biceps', labelMatchers: {'biceps'}),
        _DivisionSection(title: 'Triceps', labelMatchers: {'triceps'}),
        _DivisionSection(title: 'Hamstrings', labelMatchers: {'hamstrings'}),
        _DivisionSection(title: 'Calves', labelMatchers: {'calves'}),
        _DivisionSection(title: 'Forearms', labelMatchers: {'forearms'}),
        _DivisionSection(title: 'Other', labelMatchers: {}, isOther: true),
      ];
    case _ExerciseDivision.pushPullLegs:
      return const [
        _DivisionSection(title: 'Push', labelMatchers: {'push'}),
        _DivisionSection(title: 'Pull', labelMatchers: {'pull'}),
        _DivisionSection(title: 'Legs', labelMatchers: {'legs'}),
        _DivisionSection(title: 'Other', labelMatchers: {}, isOther: true),
      ];
    case _ExerciseDivision.upperLower:
      return const [
        _DivisionSection(
          title: 'Upper',
          labelMatchers: {
            'push',
            'pull',
            'chest',
            'upper pecs',
            'shoulders',
            'rear delts',
            'upper back',
            'lats',
            'arms',
            'biceps',
            'triceps',
            'forearms',
          },
        ),
        _DivisionSection(
          title: 'Lower',
          labelMatchers: {
            'legs',
            'quads',
            'glutes',
            'hamstrings',
            'calves',
            'posterior chain',
          },
        ),
        _DivisionSection(title: 'Other', labelMatchers: {}, isOther: true),
      ];
    case _ExerciseDivision.compoundIsolation:
      return const [
        _DivisionSection(title: 'Compound', labelMatchers: {'compound'}),
        _DivisionSection(title: 'Isolation', labelMatchers: {'isolation'}),
        _DivisionSection(title: 'Other', labelMatchers: {}, isOther: true),
      ];
    case _ExerciseDivision.allExercises:
      return const [
        _DivisionSection(title: 'All exercises', labelMatchers: {}),
      ];
  }
}

String _divisionLabel(_ExerciseDivision division) {
  switch (division) {
    case _ExerciseDivision.muscles:
      return 'Muscles';
    case _ExerciseDivision.pushPullLegs:
      return 'Push-pull-legs';
    case _ExerciseDivision.upperLower:
      return 'Upper-lower';
    case _ExerciseDivision.compoundIsolation:
      return 'Compound-isolation';
    case _ExerciseDivision.allExercises:
      return 'All exercises';
  }
}

String _orderingLabel(_ExerciseOrdering ordering) {
  switch (ordering) {
    case _ExerciseOrdering.alphabetic:
      return 'Alphabetic order';
    case _ExerciseOrdering.createdAt:
      return 'Date of creation';
    case _ExerciseOrdering.mostUsed:
      return 'Most used';
  }
}

class _DeleteCircleTrashIcon extends StatelessWidget {
  const _DeleteCircleTrashIcon({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Icon(Icons.delete_outline, size: 12, color: iconColor),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
