// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasirku/screens/login_screen.dart';

void main() {
  testWidgets('login screen displays Firebase data notice',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('Data barang tersimpan di Firebase'), findsOneWidget);
    expect(
      find.text('Data otomatis tersinkron di semua perangkat'),
      findsOneWidget,
    );
  });
}
