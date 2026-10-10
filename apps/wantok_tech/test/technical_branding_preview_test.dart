import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_tech/src/dashboard/technical_branding_page.dart';

void main() {
  const draft = <String, dynamic>{
    'theme': <String, dynamic>{
      'mode': 'light',
      'primary': '#156C49',
      'secondary': '#F3C846',
      'cardRadius': 20,
    },
    'media': <String, dynamic>{},
  };

  for (final device in ['mobile', 'tablet', 'desktop']) {
    testWidgets('$device draft preview keeps visuals isolated', (tester) async {
      tester.view.physicalSize = const Size(1250, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: BrandingDevicePreview(
                document: draft,
                device: device,
                category: 'education-training',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wantok Services'), findsOneWidget);
      expect(find.text('Popular categories'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text(device.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
