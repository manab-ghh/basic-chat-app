// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/login/login_screen.dart';
import 'package:frontend/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ChatApp mounts successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChatApp()));
    expect(find.byType(ChatApp), findsOneWidget);
  });

  testWidgets('SplashScreen displays app name', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('ChatApp'), findsOneWidget);
  });

  testWidgets('LoginScreen displays login form', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
