import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootShell extends StatelessWidget {
  const RootShell({
    required this.state,
    required this.child,
    super.key,
  });

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = state.uri.path;
    final selectedIndex = _indexForLocation(location);
    final isTabRoot = _isTabRootLocation(location);

    return Scaffold(
      appBar: isTabRoot
          ? AppBar(
              title: Text(_titleForIndex(selectedIndex)),
              actions: _actionsForIndex(selectedIndex, context),
            )
          : null,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.view_week_outlined),
            label: 'Splits',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Exercises',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Other'),
        ],
        onDestinationSelected: (index) => context.go(_pathForIndex(index)),
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/splits')) {
      return 1;
    }
    if (location.startsWith('/exercises')) {
      return 2;
    }
    if (location.startsWith('/other')) {
      return 3;
    }
    return 0;
  }

  bool _isTabRootLocation(String location) {
    return location == '/home' ||
        location == '/splits' ||
        location == '/exercises' ||
        location == '/other';
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Splits';
      case 2:
        return 'Exercises';
      case 3:
        return 'Other';
      default:
        return 'Home';
    }
  }

  String _pathForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/splits';
      case 2:
        return '/exercises';
      case 3:
        return '/other';
      default:
        return '/home';
    }
  }

  List<Widget>? _actionsForIndex(int index, BuildContext context) {
    if (index == 1) {
      return [
        IconButton(
          key: const Key('splits_add_button'),
          tooltip: 'Create split',
          onPressed: () => context.push('/splits/builder'),
          icon: const Icon(Icons.add_circle, size: 36),
        ),
      ];
    }

    if (index == 2) {
      return [
        IconButton(
          key: const Key('exercises_add_button'),
          tooltip: 'Create exercise',
          onPressed: () => context.push('/exercises/new'),
          icon: const Icon(Icons.add_circle, size: 36),
        ),
      ];
    }

    return null;
  }
}
