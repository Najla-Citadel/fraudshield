// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:fraudshield/main.dart';

void main() {
  testWidgets('App renders Login screen smoke test', (WidgetTester tester) async {
    // Load mock env vars for testing
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000/api/v1');

    // Build our app and trigger a frame.
    await tester.pumpWidget(const FraudShieldApp());
    
    // Allow animations to start but don't wait for them to finish (they are infinite)
    await tester.pump(const Duration(seconds: 2));

    // Verify that we start at the Login screen (because no auth token)
    expect(find.text('Login'), findsOneWidget);
    // Note: AdaptiveTextField label might be inside InputDecorator, so we check for hinted text or label
    expect(find.text('Email Address'), findsOneWidget);
  });
}
