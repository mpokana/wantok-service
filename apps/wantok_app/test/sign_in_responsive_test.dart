import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/auth/sign_in_page.dart';
import 'package:wantok_ui/wantok_ui.dart';

Future<void> pumpSignIn(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: WantokTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: const SignInPage(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 800.0]) {
    testWidgets(
      'Sign-in branding and form fit $width with enlarged text',
      (tester) async {
        await pumpSignIn(tester, width: width, textScale: 1.5);
        expect(find.text('Wantok Services'), findsOneWidget);
        expect(find.text('People. Places. Possibilities.'), findsOneWidget);
        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Narrow sign-in can switch to account creation and back', (
    tester,
  ) async {
    await pumpSignIn(tester, width: 320, textScale: 1.5);
    await tester.ensureVisible(find.text('New to Wantok? Create an account'));
    await tester.tap(find.text('New to Wantok? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Full name'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Already have an account? Sign in'));
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
