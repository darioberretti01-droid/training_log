import 'package:flutter/material.dart';

import 'package:training_log_app/l10n/app_localizations.dart';

Widget localizedTestApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
