enum DemoFixtureScenario {
  baseRealistic,
  homeKeepLoggingToday,
  homeNoCurrentSplit,
  homeLastUsedExistsNotCurrent,
  homeLastUsedDeleted,
  homeNoSessions,
  loggerSplitWithUnfilledRows,
}

extension DemoFixtureScenarioX on DemoFixtureScenario {
  String get id {
    switch (this) {
      case DemoFixtureScenario.baseRealistic:
        return 'base_realistic';
      case DemoFixtureScenario.homeKeepLoggingToday:
        return 'home_keep_logging_today';
      case DemoFixtureScenario.homeNoCurrentSplit:
        return 'home_no_current_split';
      case DemoFixtureScenario.homeLastUsedExistsNotCurrent:
        return 'home_last_used_exists_not_current';
      case DemoFixtureScenario.homeLastUsedDeleted:
        return 'home_last_used_deleted';
      case DemoFixtureScenario.homeNoSessions:
        return 'home_no_sessions';
      case DemoFixtureScenario.loggerSplitWithUnfilledRows:
        return 'logger_split_with_unfilled_rows';
    }
  }
}

class DemoFixtureIds {
  static const String splitUpperLower = 'split_upper_lower';
  static const String splitPushPullLegs = 'split_push_pull_legs';
  static const String splitFullBody = 'split_full_body';

  static const String dayUpperA = 'day_upper_a';
  static const String dayLowerA = 'day_lower_a';
  static const String dayPush = 'day_push';
  static const String dayPull = 'day_pull';
  static const String dayLegs = 'day_legs';
  static const String dayFullBodyA = 'day_full_body_a';
  static const String dayFullBodyB = 'day_full_body_b';
}
