import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/screens/auth_screen.dart';

void main() {
  group('AuthScreen', () {
    testWidgets('AuthScreen displays login form by default', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

      // Verify that the login form is displayed
      expect(find.text('Login').first, findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify that signup fields are not visible
      expect(find.text('First Name'), findsNothing);
      expect(find.text('Last Name'), findsNothing);
      expect(find.text('Username'), findsNothing);
    });

    testWidgets('Toggle button switches to signup form', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

      // Tap the toggle button
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pumpAndSettle();

      // Verify that the signup form is displayed
      expect(find.text('Sign Up').first, findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);

      // Verify that login button text changed
      expect(find.text('Already have an account? Login'), findsOneWidget);
    });

    testWidgets('Form validation works for email field', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

      // Try to submit empty form
      await tester.tap(find.text('Login').first);
      await tester.pump();

      // Verify that error message is shown
      expect(find.text('Please enter your email'), findsOneWidget);
    });
  });
}
