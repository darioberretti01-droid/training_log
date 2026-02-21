import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_log_app/core/widgets/label_pill_selector.dart';

void main() {
  testWidgets('add action shows ADD LABEL with same color as plus icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _SelectorHost(
            availableLabels: ['chest', 'back'],
            initialSelected: [],
          ),
        ),
      ),
    );

    final addChip = tester.widget<ActionChip>(find.byKey(const Key('label_selector_add')));
    final label = addChip.label as Text;
    final icon = addChip.avatar as Icon;

    expect(label.data, 'ADD LABEL');
    expect(label.style?.color, icon.color);
  });

  testWidgets('search with no matches still shows ADD LABEL and keeps selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _SelectorHost(
            availableLabels: ['chest', 'back'],
            initialSelected: ['chest'],
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('label_selector_search')), 'zzz');
    await tester.pump();

    expect(find.byType(FilterChip), findsNothing);
    expect(find.byKey(const Key('label_selector_add')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('label_selector_search')), '');
    await tester.pump();

    final chestChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'chest'),
    );
    expect(chestChip.selected, isTrue);
  });

  testWidgets('cancel add-label dialog does not crash or call create callback', (
    tester,
  ) async {
    var createCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _SelectorHost(
            availableLabels: const ['chest'],
            initialSelected: const [],
            onCreateLabel: (_) async {
              createCalls += 1;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('label_selector_add')));
    await tester.pumpAndSettle();
    expect(find.text('Create Label'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(createCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding label normalizes and auto-selects created label', (
    tester,
  ) async {
    final createdLabels = <String>[];
    List<String> selected = const [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _SelectorHost(
            availableLabels: const ['chest'],
            initialSelected: const [],
            onCreateLabel: (label) async {
              createdLabels.add(label);
              return true;
            },
            onSelectedChanged: (value) {
              selected = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('label_selector_add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Forearms');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(createdLabels, ['forearms']);
    expect(selected, contains('forearms'));
  });
}

class _SelectorHost extends StatefulWidget {
  const _SelectorHost({
    required this.availableLabels,
    required this.initialSelected,
    this.onCreateLabel,
    this.onSelectedChanged,
  });

  final List<String> availableLabels;
  final List<String> initialSelected;
  final Future<bool> Function(String label)? onCreateLabel;
  final ValueChanged<List<String>>? onSelectedChanged;

  @override
  State<_SelectorHost> createState() => _SelectorHostState();
}

class _SelectorHostState extends State<_SelectorHost> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.initialSelected];
  }

  @override
  Widget build(BuildContext context) {
    return LabelPillSelector(
      availableLabels: widget.availableLabels,
      selectedLabels: _selected,
      onSelectedLabelsChanged: (labels) {
        setState(() {
          _selected = labels;
        });
        widget.onSelectedChanged?.call(labels);
      },
      onCreateLabel: widget.onCreateLabel ?? (_) async => true,
    );
  }
}
