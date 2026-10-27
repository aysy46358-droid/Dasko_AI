import 'package:flutter_test/flutter_test.dart';
import 'package:dasko_ai/app/app.dart';

void main() {
  testWidgets('DaskoApp builds the application shell', (tester) async {
    await tester.pumpWidget(const DaskoApp());

    expect(find.byType(DaskoApp), findsOneWidget);
  });
}
