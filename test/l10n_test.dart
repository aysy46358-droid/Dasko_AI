import 'dart:async';

import 'package:dasko_ai/app/app.dart';
import 'package:dasko_ai/core/constants/app_constants.dart';
import 'package:dasko_ai/core/providers.dart';
import 'package:dasko_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeLoadingKey = ValueKey<String>('locale-restoring');
const _englishButtonKey = ValueKey<String>('switch-to-english');
const _arabicButtonKey = ValueKey<String>('switch-to-arabic');

class _LocalizedProbe extends StatelessWidget {
  const _LocalizedProbe();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(AppLocalizations.of(context)!.appName)),
    );
  }
}

class _LocaleSwitchProbe extends ConsumerWidget {
  const _LocaleSwitchProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          Text(Directionality.of(context).name,
              key: const ValueKey('direction')),
          TextButton(
            key: _englishButtonKey,
            onPressed: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('en')),
            child: const Text('English'),
          ),
          TextButton(
            key: _arabicButtonKey,
            onPressed: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('ar')),
            child: const Text('Arabic'),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('restores the saved locale before rendering localized content', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.keyLocale: 'en',
    });
    final preferences = await SharedPreferences.getInstance();
    final preferencesGate = Completer<SharedPreferences>();
    final notifier = LocaleNotifier(
      loadPreferences: () => preferencesGate.future,
    );

    await tester.pumpWidget(
      DaskoApp(
        overrides: [localeProvider.overrideWith((ref) => notifier)],
        home: const _LocalizedProbe(),
      ),
    );

    expect(find.byKey(_localeLoadingKey), findsOneWidget);
    expect(find.text('Dasko AI'), findsNothing);

    preferencesGate.complete(preferences);
    await tester.pumpAndSettle();

    expect(find.byKey(_localeLoadingKey), findsNothing);
    expect(find.text('Dasko AI'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Dasko AI'))),
      TextDirection.ltr,
    );
  });

  testWidgets('last language selection wins while restoration is pending', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.keyLocale: 'en',
    });
    final preferences = await SharedPreferences.getInstance();
    final preferencesGate = Completer<SharedPreferences>();
    final notifier = LocaleNotifier(
      loadPreferences: () => preferencesGate.future,
    );

    await tester.pumpWidget(
      DaskoApp(
        overrides: [localeProvider.overrideWith((ref) => notifier)],
        home: const _LocalizedProbe(),
      ),
    );

    await notifier.setLocale(const Locale('en'));
    await notifier.setLocale(const Locale('ar'));
    expect(notifier.state.locale, const Locale('ar'));
    expect(notifier.state.isInitialized, isFalse);

    preferencesGate.complete(preferences);
    await tester.pumpAndSettle();

    expect(notifier.state.locale, const Locale('ar'));
    expect(notifier.state.isInitialized, isTrue);
    expect(preferences.getString(AppConstants.keyLocale), 'ar');
  });

  testWidgets('switching Arabic and English updates text direction', (
    tester,
  ) async {
    await tester.pumpWidget(const DaskoApp(home: _LocaleSwitchProbe()));
    await tester.pumpAndSettle();

    expect(find.text('rtl'), findsOneWidget);

    await tester.tap(find.byKey(_englishButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('ltr'), findsOneWidget);

    await tester.tap(find.byKey(_arabicButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('rtl'), findsOneWidget);
  });

  test('localized greeting uses generated ARB placeholders', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));

    expect(english.introGreeting(english.robotName), 'Welcome, Dasko.');
    expect(arabic.introGreeting(arabic.robotName), 'أهلاً بك يا داسكو.');
  });
}
