import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('TECHNI')),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('TECHNI'), findsOneWidget);
  });
}
