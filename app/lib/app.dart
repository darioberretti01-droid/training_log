import 'package:flutter/material.dart';

import 'ui/app_router.dart';

class TrainingLogApp extends StatelessWidget {
  const TrainingLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    final outlinedActionStyle = OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: colorScheme.outline),
    );

    return MaterialApp.router(
      title: 'Training Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(style: outlinedActionStyle),
      ),
      routerConfig: appRouter,
    );
  }
}
