import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dasko_ai/core/errors/failures.dart';
import 'package:dasko_ai/domain/usecases/send_message.dart';
import 'package:dasko_ai/features/chat/application/chat_notifier.dart';
import 'package:dasko_ai/features/chat/presentation/chat_screen.dart';
import 'package:dasko_ai/features/chat/presentation/interactive_dasko_robot.dart';
import 'package:dasko_ai/services/ai_engine/ai_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CompleterEngine implements AiEngine {
  final Completer<Either<Failure, String>> completer =
      Completer<Either<Failure, String>>();

  @override
  Future<Either<Failure, String>> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  }) {
    return completer.future;
  }
}

DaskoRobotState _robotState(WidgetTester tester) {
  return tester
      .widget<InteractiveDaskoRobot>(
        find.byType(InteractiveDaskoRobot),
      )
      .state;
}

void main() {
  testWidgets('chat request drives robot into thinking until reply completes', (
    tester,
  ) async {
    final engine = _CompleterEngine();
    final notifier = ChatNotifier(SendMessage(engine));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: ChatScreen(robotViewerOverride: SizedBox.shrink()),
        ),
      ),
    );

    expect(_robotState(tester), DaskoRobotState.ready);

    await tester.enterText(find.byType(TextField), 'اختبار حركة الروبوت');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(_robotState(tester), DaskoRobotState.thinking);
    expect(find.text('أفكر بالرد...'), findsOneWidget);

    engine.completer.complete(const Right<Failure, String>('تم الرد'));
    await tester.pump();

    expect(_robotState(tester), DaskoRobotState.ready);
    expect(find.text('جاهز لمساعدتك'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
