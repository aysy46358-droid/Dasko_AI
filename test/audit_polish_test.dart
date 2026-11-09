import 'package:dasko_ai/app/providers.dart';
import 'package:dasko_ai/core/theme/app_theme.dart';
import 'package:dasko_ai/core/theme/app_theme_mode.dart';
import 'package:dasko_ai/domain/entities/message.dart';
import 'package:dasko_ai/features/chat/application/chat_notifier.dart';
import 'package:dasko_ai/features/chat/presentation/chat_screen.dart';
import 'package:dasko_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('ChatState exposes messages as an unmodifiable view', () {
    final state = ChatState(
      messages: [
        Message(
          id: '1',
          text: 'hello',
          isUser: true,
          createdAt: DateTime(2026),
        ),
      ],
    );

    expect(state.messages, hasLength(1));
    expect(
      () => state.messages.add(
        Message(
          id: '2',
          text: 'nope',
          isUser: false,
          createdAt: DateTime(2026),
        ),
      ),
      throwsUnsupportedError,
    );
  });

  testWidgets('Dark palette paints a flat pitch-black canvas', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeProvider.notifier).setTheme(AppThemeMode.dark);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark,
          home: const ChatScreen(),
        ),
      ),
    );
    await tester.pump();

    final canvases = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
    expect(
      canvases.any((box) => box.color == AppTheme.darkBackground),
      isTrue,
      reason: 'Dark mode must not paint the space gradient',
    );
  });
}
