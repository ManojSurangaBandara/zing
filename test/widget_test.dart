import 'package:flutter_test/flutter_test.dart';
import 'package:zing/main.dart';

void main() {
  testWidgets('ZingApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZingApp());
    expect(find.byType(ZingApp), findsOneWidget);
  });
}
