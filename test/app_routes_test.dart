import 'package:dasko_ai/app/app.dart';
import 'package:dasko_ai/features/chat/presentation/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('chat settings action resolves through the app route table', (
    tester,
  ) async {
    await tester.pumpWidget(const DaskoApp(home: ChatScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final settingsButton = find.byIcon(Icons.settings);
    expect(settingsButton, findsOneWidget);

    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('الإعدادات'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
