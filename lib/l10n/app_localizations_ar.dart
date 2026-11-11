// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'داسكو AI';

  @override
  String get appWordmark => 'DASKO AI';

  @override
  String get robotName => 'داسكو';

  @override
  String get robotAlt => 'روبوت متوهج ثنائي الأبعاد';

  @override
  String get chatInputHint => 'اكتب رسالتك...';

  @override
  String get thinkingRobot => 'أفكر بالرد...';

  @override
  String get readyRobot => 'جاهز لمساعدتك';

  @override
  String introGreeting(String name) {
    return 'أهلاً بك يا $name.';
  }

  @override
  String get startChat => 'ابدأ المحادثة';

  @override
  String get errorUnknown => 'تعذر إكمال طلبك. يرجى المحاولة لاحقاً.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get themeSectionTitle => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeNeon => 'نيون';

  @override
  String get languageSectionTitle => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

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
