import 'package:flutter/material.dart';

import 'ui/app_router.dart';

class TrainingLogApp extends StatelessWidget {
  const TrainingLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Training Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
