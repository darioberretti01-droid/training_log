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
  ConsumerState<ExerciseListContent> createState() => _ExerciseListContentState();
}

class _ExerciseListContentState extends ConsumerState<ExerciseListContent> {
  final TextEditingController _searchController = TextEditingController();
  _ExerciseDivision _division = _ExerciseDivision.muscles;
  _ExercisePresentation _presentation = _ExercisePresentation.pills;
  _ExerciseOrdering _ordering = _ExerciseOrdering.alphabetic;
  bool _ascending = true;
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
        final createdAtMap = ref.watch(exerciseCreatedAtMapProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <String, int>{},
        );
        final logCountMap = ref.watch(exerciseLogCountMapProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <String, int>{},
        );
        return exercisesState.when(
          data: (exercises) => _buildLoaded(context, exercises, createdAtMap, logCountMap),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildDivisionAndOrderingControls(context, addActionColor),
        const SizedBox(height: 8),
        SegmentedButton<_ExercisePresentation>(
          key: const Key('exercises_view_toggle'),
          segments: const [
            ButtonSegment(
              value: _ExercisePresentation.pills,
              icon: Icon(Icons.local_offer_outlined),
              label: Text('Pills'),
            ),
            ButtonSegment(
              value: _ExercisePresentation.list,
              icon: Icon(Icons.view_list_outlined),
              label: Text('List'),
            ),
          ],
          selected: {_presentation},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            setState(() => _presentation = selection.first);
          },
        ),
        const SizedBox(height: 12),
        if (sections.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('No exercises match the current filter.'),
            ),
          )
        else
          ...sections.map((section) => _buildSection(context, section)),
      ],
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
    );
  }

  Widget _buildDivisionAndOrderingControls(
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
              child: Text(_divisionLabel(value), overflow: TextOverflow.ellipsis),
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
      label: Text(
        'ADD EXERCISE',
        style: TextStyle(color: addActionColor),
      ),
      onPressed: () => context.push('/exercises/new'),
    );

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
              child: Text(_orderingLabel(value), overflow: TextOverflow.ellipsis),
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

    final invertButton = IconButton(
      key: const Key('exercises_order_invert_button'),
      tooltip: _ascending ? 'Ascending' : 'Descending',
      onPressed: () => setState(() => _ascending = !_ascending),
      icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;
        if (isNarrow) {
          return Column(
            children: [
              Row(
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
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: orderingDropdown),
                  const SizedBox(width: 4),
                  invertButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: divisionDropdown),
                  const SizedBox(width: 8),
                  addButton,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: orderingDropdown),
            const SizedBox(width: 4),
            invertButton,
          ],
        );
      },
    );
  }

  List<_ExerciseListItem> _toFilteredItems(
    List<ExerciseWithLabels> exercises,
    Map<String, int> createdAtMap,
    Map<String, int> logCountMap,
  ) {
    final filtered = <_ExerciseListItem>[];
    for (final exercise in exercises) {
      if (_query.isNotEmpty &&
          !exercise.name.toLowerCase().contains(_query)) {
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
      return [
        _ExerciseSection(title: definitions.first.title, items: items),
      ];
    }

    final otherSection = definitions.last;
    for (final item in items) {
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
      final targetTitle = matched?.title ?? otherSection.title;
      byTitle[targetTitle]!.add(item);
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

  Widget _buildSection(BuildContext context, _ExerciseSection section) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
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
                    (item) => ActionChip(
                      key: Key('exercise_pill_${item.exercise.id}'),
                      label: Text(item.exercise.name),
                      onPressed: () =>
                          context.push('/exercises/${item.exercise.id}/history'),
                    ),
                  )
                  .toList(growable: false),
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
                        key: Key('exercise_list_${item.exercise.id}'),
                        title: Text(item.exercise.name),
                        subtitle: item.exercise.labels.isEmpty
                            ? null
                            : Text(item.exercise.labels.join(', ')),
                        onTap: () =>
                            context.push('/exercises/${item.exercise.id}/history'),
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
}

class _ExerciseListItem {
  _ExerciseListItem({
    required this.exercise,
    required this.createdAtMs,
    required this.logCount,
  }) : nameLower = exercise.name.toLowerCase(),
       labelsLower = exercise.labels.map((label) => label.toLowerCase()).toSet();

  final ExerciseWithLabels exercise;
  final int createdAtMs;
  final int logCount;
  final String nameLower;
  final Set<String> labelsLower;

  bool matches(Set<String> matchers) => labelsLower.any(matchers.contains);
}

class _ExerciseSection {
  const _ExerciseSection({
    required this.title,
    required this.items,
  });

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
        _DivisionSection(title: 'Chest', labelMatchers: {'chest', 'upper pecs'}),
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
