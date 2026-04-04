import 'package:flutter_test/flutter_test.dart';

import 'package:nitaai_flutter/app/nitaai_app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NitaAiApp());

    // Verify that our app shows the Chat tab.
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
  });
}
