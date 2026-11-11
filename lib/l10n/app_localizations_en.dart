// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dasko AI';

  @override
  String get appWordmark => 'DASKO AI';

  @override
  String get robotName => 'Dasko';

  @override
  String get robotAlt => '2D glowing robot';

  @override
  String get chatInputHint => 'Type your message...';

  @override
  String get thinkingRobot => 'Thinking...';

  @override
  String get readyRobot => 'Ready to help';

  @override
  String introGreeting(String name) {
    return 'Welcome, $name.';
  }

  @override
  String get startChat => 'Start the conversation';

  @override
  String get errorUnknown =>
      'Could not complete your request. Please try again later.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get themeSectionTitle => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeNeon => 'Neon';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get cinematicLocalCore => 'LOCAL CORE';

  @override
  String get cinematicTagline => 'YOUR INTELLIGENCE. YOUR SPACE.';

  @override
  String get cinematicWelcome => 'Always here. Always yours.';

  @override
  String get cinematicDescription => 'A private companion, powered by you.';

  @override
  String get cinematicEnter => 'ENTER YOUR SPACE';

  @override
  String get cinematicPrivacy => 'PRIVATE BY DESIGN  •  READY WHEN YOU ARE';
}
