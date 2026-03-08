import 'package:drift/drift.dart';

import '../db/app_database.dart';

class AppSettingsStorage {
  AppSettingsStorage(this._database);

  final AppDatabase _database;

  static const _languageCodeKey = 'language_code';

  Future<String?> loadLanguageCode() async {
    final result = await _database
        .customSelect(
          'SELECT value FROM app_settings WHERE key = ? LIMIT 1',
          variables: [Variable.withString(_languageCodeKey)],
        )
        .getSingleOrNull();
    if (result == null) {
      return null;
    }
    return result.readNullable<String>('value');
  }

  Future<void> saveLanguageCode(String languageCode) async {
    await _database.customStatement(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
      [_languageCodeKey, languageCode],
    );
  }

  Future<void> clearLanguageCode() async {
    await _database.customStatement('DELETE FROM app_settings WHERE key = ?', [
      _languageCodeKey,
    ]);
  }
}
