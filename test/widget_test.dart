import 'package:dasko_ai/app/app.dart';
import 'package:dasko_ai/core/constants/app_assets.dart';
import 'package:dasko_ai/features/chat/presentation/interactive_dasko_robot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DaskoApp builds the application shell', (tester) async {
    await tester.pumpWidget(const DaskoApp());

    expect(find.byType(DaskoApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('robot keeps the requested size for each visual state', (
    tester,
  ) async {
    const sizes = [82.0, 112.0, 205.0, 245.0];

    for (final size in sizes) {
      for (final state in DaskoRobotState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: InteractiveDaskoRobot(state: state, size: size),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 80));

        final robot = find.byType(InteractiveDaskoRobot);
        expect(robot, findsOneWidget);
        expect(tester.getSize(robot), Size.square(size));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('robot renders the poster asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: InteractiveDaskoRobot(state: DaskoRobotState.ready),
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, AppAssets.robotPoster);
    expect(image.fit, BoxFit.contain);
  });
}
