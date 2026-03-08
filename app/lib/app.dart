import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/state/providers.dart';
import 'l10n/app_localizations.dart';
import 'ui/app_router.dart';

class TrainingLogApp extends ConsumerWidget {
  const TrainingLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocale = ref
        .watch(appLocaleProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    final outlinedActionStyle = OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: colorScheme.outline),
    );

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.tr('Training Log'),
      debugShowCheckedModeBanner: false,
      locale: selectedLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(style: outlinedActionStyle),
      ),
      routerConfig: appRouter,
    );
  }
}
