import 'package:dasko_ai/core/theme/app_theme.dart';
import 'package:dasko_ai/features/chat/presentation/chat_screen.dart';
import 'package:dasko_ai/app/providers.dart';
import 'package:dasko_ai/core/theme/app_theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal shell that wires [themeProvider] into `MaterialApp` the same way
/// `DaskoApp` does, so the test can flip palettes without touching the UI.
class _ThemedChatApp extends ConsumerWidget {
  const _ThemedChatApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.themeDataFor(ref.watch(themeProvider)),
      home: const ChatScreen(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('switching to light mode changes the Scaffold background', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _ThemedChatApp(),
      ),
    );
    await tester.pump();

    final scaffold = find.byType(Scaffold).first;
    final neonBackground = tester.widget<Scaffold>(scaffold).backgroundColor;
    expect(neonBackground, AppTheme.neon.scaffoldBackgroundColor);

    container.read(themeProvider.notifier).setTheme(AppThemeMode.light);
    // MaterialApp cross-fades themes through AnimatedTheme, so the first frame
    // still shows the old palette; advance past kThemeAnimationDuration. The
    // space background animates forever, so pumpAndSettle would never return.
    await tester.pump();
    await tester.pump(
      kThemeAnimationDuration + const Duration(milliseconds: 50),
    );

    final lightBackground = tester.widget<Scaffold>(scaffold).backgroundColor;
    expect(lightBackground, AppTheme.light.scaffoldBackgroundColor);
    expect(lightBackground, isNot(neonBackground));
  });
}
